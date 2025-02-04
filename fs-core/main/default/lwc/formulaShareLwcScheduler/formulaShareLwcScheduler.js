import { LightningElement, track } from "lwc";
import getCurrentlyScheduledCron from "@salesforce/apex/FormulaShareLWCSchedulingService.getCurrentlyScheduledCron";
import scheduleJob from "@salesforce/apex/FormulaShareLWCSchedulingService.scheduleJob";
import deleteScheduledJob from "@salesforce/apex/FormulaShareLWCSchedulingService.deleteScheduledJob";
import LOCALE from "@salesforce/i18n/locale";

export default class LwcScheduler extends LightningElement {
  cronJobName = "FormulaShare Full Recalculation";
  
  // Currently scheduled job details
  @track currentCronAsTime;
  currentCronAsString;
  @track currentScheduleDescription;
  currentCronTrigger;
  
  // Form input tracking
  @track selectedTime;
  @track selectedCronString;
  scheduleType = 'daily'; // Default to daily schedule
  
  // Individual day tracking
  @track mondaySelected = true;
  @track tuesdaySelected = true;
  @track wednesdaySelected = true;
  @track thursdaySelected = true;
  @track fridaySelected = true;
  @track saturdaySelected = true;
  @track sundaySelected = true;

  // Component state
  @track state; // test, schedule, reschedule
  @track loading = false; // Initialize loading to false
  dateTimeSubmitted;

  // Schedule type options for radio group
  get scheduleOptions() {
    return [
      { label: 'Daily', value: 'daily' },
      { label: 'Specific Days', value: 'weekly' }
    ];
  }

  // Show day selection checkboxes only for weekly schedule
  get showDaySelection() {
    return this.scheduleType === 'weekly';
  }

  // Description of current schedule for display
  @track scheduleDescPrefix;
  @track scheduleDescDetail;

  get scheduleDescription() {
    if (!this.scheduleDescPrefix) return 'No schedule set';
    return this.scheduleDescDetail ? 
        `${this.scheduleDescPrefix} ${this.scheduleDescDetail}` : 
        this.scheduleDescPrefix;
  }

  connectedCallback() {
    this.loading = true;
    if(LOCALE) { // Only call if locale is already available
      this.getScheduledCron();
    }
  }

  /**
   * On component load - we want to check to see if the job is currently scheduled. If it is
   * scheduled - we can modify the state appropriatley.
   */

  getScheduledCron() {
    getCurrentlyScheduledCron()
      .then(result => {
        if (!result) {
          console.log("No job currently scheduled");
          this.state = "schedule";
          this.scheduleDescPrefix = "Multiple times per day";
          this.scheduleDescDetail = null;
          this.scheduleType = 'daily';
        } else {
          this.currentCronTrigger = result;
          this.currentCronAsTime = this.convertCronToTime(result.cronExpression);
          this.selectedTime = this.currentCronAsTime;
          this.state = "reschedule";
          this.scheduleDescPrefix = null;
          this.scheduleDescDetail = null;
          this.scheduleType = null;
          
          // Parse cron string to determine schedule description
          const cronParts = result.cronExpression.split(" ");
          // [seconds] [minutes] [hours] [day of month] [month] [day of week] [optional year]
          const [seconds, minutes, hours, dayOfMonth, month, dayOfWeek] = cronParts;

          // Handle different schedule patterns
          if (hours.includes(',')) {
            // Multiple times per day
            this.scheduleDescPrefix = "Multiple times per day";
            this.scheduleType = 'daily';
          }
          else if (dayOfWeek !== '*' && dayOfWeek !== '?') {
            // Weekly schedule
            this.scheduleDescPrefix = "Weekly on";
            if (dayOfWeek.includes(',')) {
              this.scheduleDescDetail = this.parseDaysOfWeek(dayOfWeek);
            } else {
              this.scheduleDescDetail = this.getDayName(dayOfWeek);
            }

            this.scheduleType = 'weekly';
            const dayNumbers = cronParts[5].split(",").map(Number);
            const dayNames = [];
            // Reset all days to false first
            this.mondaySelected = false;
            this.tuesdaySelected = false;
            this.wednesdaySelected = false;
            this.thursdaySelected = false;
            this.fridaySelected = false;
            this.saturdaySelected = false;
            this.sundaySelected = false;
            
            // Set selected days based on cron string
            dayNumbers.forEach(num => {
              switch(num) {
                case 2: 
                  dayNames.push('Monday');
                  this.mondaySelected = true;
                  break;
                case 3: 
                  dayNames.push('Tuesday');
                  this.tuesdaySelected = true;
                  break;
                case 4: 
                  dayNames.push('Wednesday');
                  this.wednesdaySelected = true;
                  break;
                case 5: 
                  dayNames.push('Thursday');
                  this.thursdaySelected = true;
                  break;
                case 6: 
                  dayNames.push('Friday');
                  this.fridaySelected = true;
                  break;
                case 7: 
                  dayNames.push('Saturday');
                  this.saturdaySelected = true;
                  break;
                case 1:
                  dayNames.push('Sunday');
                  this.sundaySelected = true;
                  break;
              }
            });
          }
          else if (dayOfMonth !== '?' && dayOfWeek === '?') {
            // Monthly schedule
            this.scheduleDescPrefix = "Monthly on";
            this.scheduleDescDetail = `day ${dayOfMonth}`;
            this.scheduleType = 'daily';
          }          
          else {
            // Daily schedule
            this.scheduleDescPrefix = "Once per day";
            this.scheduleType = 'daily';
          }

          // Store next run time separately using Salesforce's timezone
          if (result.nextFireTime) {
            // Format the date in user's timezone
            const date = new Date(result.nextFireTime);
            this.nextRunTime = new Intl.DateTimeFormat(LOCALE, {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                timeZone: 'UTC', // Ensures the date stays in UTC, same as the setup menu
                hour12: false
            }).format(date);
//            const nextRun = new Date(result.nextFireTime);
            //this.nextRunTime = formatDate(nextRun, 'MMM d, yyyy, h:mm a');
          }
        }
        this.stopLoading(500);
      })
      .catch(error => {
        console.error('Error getting scheduled cron:', error);
        this.stopLoading(500);
      });
  }

  get scheduleLabel() {
    return this.currentCronAsTime ? "Reschedule Job" : "Schedule Job";
  }

  convertCronToTime(result) {
    let cronArray = result.split(" ");
    let [second, minute, hour] = cronArray;
    // Pad with leading zeros and ensure proper format
    return `${hour.padStart(2, '0')}:${minute.padStart(2, '0')}:00.000`;
  }

  rescheduleApexJob() {
    this.loading = true;
    // First delete existing job
    if(this.state === "reschedule") {
      deleteScheduledJob({ cronTriggerId: this.currentCronTrigger.cronTriggerId })
        .then(deleteResult => {
          if (deleteResult) {
            console.log("Deleted Job");
            // Only schedule new job if delete was successful
            return scheduleJob({
              cronString: this.selectedCronString,
              cronJobName: this.cronJobName
            });
          } else {
            throw new Error('Failed to delete existing job');
          }
        })
        .then(scheduleResult => {
          if (scheduleResult) {
            console.log("Job Scheduled Successfully");
            this.getScheduledCron(); // Refresh the current schedule
          } else {
            throw new Error('Failed to schedule new job');
          }
        })
        .catch(error => {
          console.error(error.message);
          this.loading = false; // Ensure loading is set to false on error
        })
        .finally(() => {
          this.stopLoading(500);
        });
    }
    else {
      console.log("Scheduling Job");
      scheduleJob({
        cronString: this.selectedCronString,
        cronJobName: this.cronJobName
      })
        .then(result => {
          if (result) {
            console.log("Job Scheduled Successfully");
            this.getScheduledCron(); // Refresh the current schedule
            this.dispatchEvent(new CustomEvent('refreshview'));   // Refresh parent components to clear warning
          } else {
            throw new Error('Failed to schedule job');
          }
        })
        .catch(error => {
          console.error(error.message);
          this.loading = false; // Ensure loading is set to false on error
        })
        .finally(() => {
          this.stopLoading(500);
        });
    }
  }

  deleteJob() {
    this.loading = true;
    deleteScheduledJob({ cronTriggerId: this.currentCronTrigger.cronTriggerId })
      .then(data => {
        console.log(data);
        if (data) {
          this.state = "schedule";
          this.currentCronAsTime = "";
          this.selectedTime = "";
          this.scheduleDescPrefix = null;
          this.scheduleDescDetail = null;
          this.currentCronTrigger = null;
          this.stopLoading(500);
          console.log("Job Deleted");
        } else {
          this.stopLoading(100);
          console.log("we were unable to delete this job");
        }
      })
      .catch(error => {
        this.stopLoading(100);
        console.log(error.message);
        this.loading = false; // Ensure loading is set to false on error
      });
  }

  handleTimeChange(event) {
    let time = event.target.value;
    this.selectedTime = time;
    let [hour, minute, seconds] = time.split(":");
    this.updateCronString(hour, minute);
  }

  handleScheduleTypeChange(event) {
    const value = event.target.value;
    this.scheduleType = value;
    console.log(this.scheduleType);
    if (this.selectedTime) {
      const [hour, minute] = this.selectedTime.split(':');
      this.updateCronString(hour, minute);
    }
  }

  handleDayChange(event) {
    const dayMap = {
      '0': 1,  // Sunday is 1 in Salesforce cron
      '1': 2,  // Monday is 2 in Salesforce cron
      '2': 3,  // Tuesday is 3 in Salesforce cron
      '3': 4,  // Wednesday is 4 in Salesforce cron
      '4': 5,  // Thursday is 5 in Salesforce cron
      '5': 6,  // Friday is 6 in Salesforce cron
      '6': 7   // Saturday is 7 in Salesforce cron
    };
    const day = parseInt(event.target.dataset.day);
    switch(day) {
      case 0: this.sundaySelected = !this.sundaySelected; break;
      case 1: this.mondaySelected = !this.mondaySelected; break;
      case 2: this.tuesdaySelected = !this.tuesdaySelected; break;
      case 3: this.wednesdaySelected = !this.wednesdaySelected; break;
      case 4: this.thursdaySelected = !this.thursdaySelected; break;
      case 5: this.fridaySelected = !this.fridaySelected; break;
      case 6: this.saturdaySelected = !this.saturdaySelected; break;
    }
    
    // Update cron string if we have a time set
    if (this.selectedTime) {
      const [hour, minute] = this.selectedTime.split(':');
      this.updateCronString(hour, minute);
    }
  }

  updateCronString(hour, minute) {
    if (this.scheduleType === 'daily' || 
      (this.mondaySelected && this.tuesdaySelected && this.wednesdaySelected && this.thursdaySelected && this.fridaySelected && this.saturdaySelected && this.sundaySelected)
    ) {
      this.selectedCronString = `0 ${minute} ${hour} ? * * *`;
    } else {
      // Get selected days for weekly schedule
      const selectedDayNumbers = [];
      // Use Salesforce's day numbering: 1=Sun, 2=Mon, etc.
      if (this.mondaySelected) selectedDayNumbers.push(2);
      if (this.tuesdaySelected) selectedDayNumbers.push(3);
      if (this.wednesdaySelected) selectedDayNumbers.push(4);
      if (this.thursdaySelected) selectedDayNumbers.push(5);
      if (this.fridaySelected) selectedDayNumbers.push(6);
      if (this.saturdaySelected) selectedDayNumbers.push(7);
      if (this.sundaySelected) selectedDayNumbers.push(1);
      
      // If no days selected, default to all days
      if (selectedDayNumbers.length === 0) {
        this.selectedCronString = `0 ${minute} ${hour} ? * * *`;
      } else {
        this.selectedCronString = `0 ${minute} ${hour} ? * ${selectedDayNumbers.join(",")} *`;
      }
    }
  }

  /**
   * The stopLoading utility is used to control a consistant state experience for the user - it ensures that
   * we don't have a flickering spinner effect when the state is in flux.
   * @param {timeoutValue} timeoutValue
   */

  stopLoading(timeoutValue) {
    setTimeout(() => {
      this.loading = false;
    }, timeoutValue);
  }

  // Helper methods for parsing cron expressions
  getDayName(dayNumber) {
    // Salesforce cron uses: 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
    const days = ['', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayNumber] || days[dayNumber % 7 + 1];
  }

  parseDaysOfWeek(daysString) {
    const dayNumbers = daysString.split(',').map(Number);
    // Sort the day numbers to put Sunday (1) at the end
    dayNumbers.sort((a, b) => {
      if (a === 1) return 1;
      if (b === 1) return -1;
      return a - b;
    });
    const dayNames = dayNumbers.map(num => this.getDayName(num));
    return this.formatList(dayNames);
  }

  parseMultipleTimes(hours, minutes) {
    const timesList = hours.split(',').map(hour => {
      return `${hour.padStart(2, '0')}:${minutes.padStart(2, '0')}`;
    });
    return this.formatList(timesList);
  }

  formatList(items) {
    if (items.length === 0) return '';
    if (items.length === 1) return items[0];
    if (items.length === 2) return `${items[0]} and ${items[1]}`;
    return items.slice(0, -1).join(', ') + ', and ' + items[items.length - 1];
  }
}

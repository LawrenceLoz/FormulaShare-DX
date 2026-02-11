public with sharing class FormulaShareLwcAvailabilityController {
    /**
     * Exposes availability of managed-only features to OSS LWC via Injection Service.
     * LWC can use this to conditionally render options like
     * "Users with Matching Field Value".
     */
    @AuraEnabled(cacheable=true)
    public static Boolean supportsUsersWithFieldMatch() {
        try {
            // Check if the class exists in this org (managed app present)
            // Using Type.forName to avoid compile-time dependency on managed-only class
            Type fieldMatchType = Type.forName('FormulaShareShareWithUsersWithFieldMatch');
            if (fieldMatchType != null) {
                // If we can get the type, the managed feature is available
                FormulaShareInjectionService inj = new FormulaShareInjectionService();
                List<FormulaShareShareWithBase> handlers = inj.getShareWithClasses(null);
                for (FormulaShareShareWithBase h : handlers) {
                    // Check if handler is an instance of the field match class using type comparison
                    if (String.valueOf(h).startsWith('FormulaShareShareWithUsersWithFieldMatch')) {
                        return true;
                    }
                }
            }
            return false;
        } catch (Exception e) {
            // If class not present or any error occurs in OSS => return false.
            return false;
        }
    }

    /**
     * Describe the User object and return fields suitable for matching:
     * - Text-like (String, Email, Phone, Url, EncryptedString, TextArea, Combobox)
     * - Id/Reference/Lookup/MasterDetail (match using Id)
     * - Formula (assumed to return text or Id; enforced at runtime by handler)
     */
    @AuraEnabled(cacheable=true)
    public static List<FieldOption> getUserFieldMatchOptions() {
        List<FieldOption> results = new List<FieldOption>();
        Schema.DescribeSObjectResult d = Schema.User.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fmap = d.fields.getMap();

        for (String api : fmap.keySet()) {
            Schema.DescribeFieldResult f = fmap.get(api).getDescribe();

            // Exclude system-calculated or unsupported types
            if (!f.isAccessible()) continue; // respect FLS in UI

            Schema.DisplayType t = f.getType();
            Boolean allowed =
                t == Schema.DisplayType.String ||
                t == Schema.DisplayType.TextArea ||
                t == Schema.DisplayType.Phone ||
                t == Schema.DisplayType.Email ||
                t == Schema.DisplayType.Url ||
                t == Schema.DisplayType.EncryptedString ||
                t == Schema.DisplayType.Id ||
                t == Schema.DisplayType.Reference ||
                t == Schema.DisplayType.Address ||
                t == Schema.DisplayType.Location ||
                t == Schema.DisplayType.Combobox;

            if (!allowed) continue;

            FieldOption opt = new FieldOption();
            opt.fieldApiName = api;
            opt.fieldLabel = f.getLabel();
            opt.displayType = String.valueOf(t);
            results.add(opt);
        }

        // Sort by label then API name for nicer UI
        results.sort(new FieldOptionSorter());
        return results;
    }

    public class FieldOption {
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String displayType;
    }

    public class FieldOptionSorter implements System.Comparator<FieldOption> {
        public Integer compare(FieldOption a, FieldOption b) {
            // Compare by field label first (case-insensitive)
            String labelA = getSafeString(a.fieldLabel);
            String labelB = getSafeString(b.fieldLabel);
            Integer labelComparison = labelA.toLowerCase().compareTo(labelB.toLowerCase());
            
            if (labelComparison != 0) {
                return labelComparison;
            }
            
            // If labels are equal, compare by API name (case-insensitive)
            String apiNameA = getSafeString(a.fieldApiName);
            String apiNameB = getSafeString(b.fieldApiName);
            return apiNameA.toLowerCase().compareTo(apiNameB.toLowerCase());
        }
        
        private String getSafeString(String value) {
            return value == null ? '' : value;
        }
    }
}

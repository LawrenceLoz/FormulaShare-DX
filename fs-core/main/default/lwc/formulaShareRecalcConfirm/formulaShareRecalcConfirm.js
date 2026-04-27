import { LightningElement, api } from "lwc";

export default class FormulaShareRecalcConfirm extends LightningElement {
  @api objectLabel;
  @api batchLogsUrl;

  handleConfirm() {
    this.dispatchEvent(new CustomEvent("confirm"));
  }

  handleCancel() {
    this.dispatchEvent(new CustomEvent("cancel"));
  }
}
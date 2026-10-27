<template>
	<div>
    <div class="wf-request-summary">
      <div class="wf-request-summary__group">
        <div class="wf-request-summary__title">Thông tin chính</div>
        <div class="wf-info-row"><span class="label">Kiểu tạo</span><span class="value">{{ createMode === "FREE_SIGN" ?
            "Ký tự do" : "Theo quy trình" }}</span></div>
        <div class="wf-info-row"><span class="label">Loại</span><span class="value">{{ selectedCategoryName }}</span>
        </div>
        <div class="wf-info-row"><span class="label">Workflow</span><span class="value">{{ createMode === "FREE_SIGN" ?
            "Không dùng workflow cố định" : (selectedDefinitionName || "Chưa chọn") }}</span></div>
        <div class="wf-info-row"><span class="label">Tên tài liệu</span><span class="value">{{ form.title || "Chưa nhập"
            }}</span></div>
        <div class="wf-info-row"><span class="label">Mã tham chiếu</span><span class="value">{{ form.code || "Tự sinh"
            }}</span></div>
        <div class="wf-info-row"><span class="label">Nguồn file</span><span class="value">{{ fileMethodLabel }}</span>
        </div>
        <div class="wf-info-row" style="border-bottom:none;"><span class="label">Template</span><span class="value">{{
            selectedTemplateName }}</span></div>
      </div>

      <div class="wf-request-summary__group">
        <div class="wf-request-summary__title">Cấu hình xử lý</div>
        <div class="wf-info-row"><span class="label">Ưu tiên</span><span class="value">{{ form.priority }}</span></div>
        <div class="wf-info-row"><span class="label">Hạn xử lý</span><span class="value">{{ form.dueDate || "Chưa đặt"
            }}</span></div>
        <div class="wf-info-row"><span class="label">Ký tuần tự</span><span class="value">{{ form.sequential ? "Có" :
            "Song song" }}</span></div>
        <div class="wf-info-row"><span class="label">Email thông báo</span><span class="value">{{ form.notifyEmail ?
            "Có" : "Không" }}</span></div>
        <div class="wf-info-row" style="border-bottom:none;"><span class="label">Người ký</span><span class="value">{{
            form.signers.length }} người</span></div>
      </div>
    </div>

    <div class="wf-request-summary__group" style="margin-top:16px;">
      <div class="wf-request-summary__title">Luồng ký</div>
      <div v-if="form.signers.length === 0" class="wf-empty-state" style="margin-top:0;">Chưa có người ký.</div>
      <div v-else>
        <div v-for="(signer, index) in form.signers" :key="signer.localId" class="wf-request-summary__signer">
          <div class="wf-request-summary__index">{{ index + 1 }}</div>
          <div style="flex:1;">
            <div class="wf-request-summary__signer-name">{{ signer.personName || signer.roleName || signer.roleCode }}
            </div>
            <div class="wf-request-summary__signer-sub">{{ signer.stepName || "Ad-hoc" }} · {{ signer.method }}</div>
          </div>
        </div>
      </div>
    </div>

    <div class="wf-request-summary__group" style="margin-top:16px;">
      <div class="wf-request-summary__title">Payload runtime Phase 2</div>
      <pre class="wf-request-json">{{ submitPayloadText }}</pre>
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-request-summary",
  props: {
    selectedCategoryName: { type: String, default: "Chưa chọn" },
    createMode: { type: String, default: "TEMPLATE_FLOW" },
    selectedDefinitionName: { type: String, default: "" },
    selectedTemplateName: { type: String, default: "Chưa chọn" },
    fileMethodLabel: { type: String, default: "" },
    submitPayloadText: { type: String, default: "" },
    form: {
      type: Object,
      default: function () {
        return { signers: [] };
      }
    }
  }
	}
</script>
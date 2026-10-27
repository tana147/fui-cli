<template>
	<div class="wf-request-detail-doc-info wf-request-detail-doc-info--basic">
    <div class="wf-info-row"><span class="label">{{ documentIdLabel }}</span><span class="value">{{ documentIdValue }}</span></div>
    <div class="wf-info-row"><span class="label">Trạng thái hồ sơ</span><span class="value">{{ contractStatusText }}</span></div>
    <div class="wf-info-row"><span class="label">Trạng thái ký</span><span class="value">{{ signStatusText }}</span></div>
    <div class="wf-info-row"><span class="label">Kiểm tra lần cuối</span><span class="value">{{ lastSyncText }}</span></div>
    <div class="wf-info-row"><span class="label">Hướng xử lý</span><span class="value">
      Tài liệu đang chờ người ký xử lý trên hệ thống {{ providerText }}. Không cần bấm ký SmartCA trong giao diện LHBS cho bước này.
    </span></div>
    <div class="wf-info-row"><span class="label">Nền tảng</span><span class="value">{{ providerText }}</span></div>
    <div class="wf-info-row"><span class="label">Theo dõi</span><span class="value">{{ trackingHelpText }}</span></div>
  </div>
</template>

<script>
	export default {
		props: {
			documentIdLabel: { type: String, default: "Mã hợp đồng" },
			documentIdValue: { type: String, default: "-" },
			contractStatusText: { type: String, default: "-" },
			signStatusText: { type: String, default: "-" },
			lastSyncText: { type: String, default: "-" },
			providerText: { type: String, default: "-" },
			trackingHelpText: { type: String, default: "" }
		}
	}
</script>
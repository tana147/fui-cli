<template>
	<div class="wf-sign-activity" :class="{ 'wf-sign-activity--compact': compact }">
    <div class="wf-sign-activity__section wf-sign-activity__section--history">
      <div class="wf-sign-activity__head">
        <h4>Lịch sử văn bản</h4>
        <v-btn class="wf-btn" variant="text" color="primary" size="small" :disabled="!documentUrl" @click="downloadDocument">
          <v-icon start="" size="14">mdi-download</v-icon>
          Tải văn bản
        </v-btn>
      </div>
      <div v-if="timelineRows.length" class="wf-sign-timeline">
        <div v-for="item in timelineRows" :key="item.key" class="wf-sign-timeline__item">
          <div class="wf-sign-timeline__dot" :class="'status-' + item.statusClass">
            <v-icon size="14">{{ item.icon }}</v-icon>
          </div>
          <div class="wf-sign-timeline__content">
            <div class="wf-sign-timeline__title">{{ item.title }}</div>
            <div class="wf-sign-timeline__meta">{{ item.timeText }}</div>
            <div v-if="item.actorText" class="wf-sign-timeline__actor">{{ item.actorText }}</div>
            <div v-if="item.subText" class="wf-sign-timeline__meta">{{ item.subText }}</div>
          </div>
        </div>
      </div>
      <div v-else="" class="wf-empty-state">Chưa có lịch sử văn bản.</div>
    </div>

    <div class="wf-sign-activity__section">
      <div class="wf-sign-activity__head">
        <h4>Chữ kí đã kí ({{ signedRows.length }})</h4>
      </div>
      <div v-if="signedRows.length" class="wf-sign-record-list">
        <button v-for="item in signedRows" :key="item.key" type="button" class="wf-sign-record" @click="openSignatureDetail(item)">
          <div class="wf-sign-record__name">{{ item.name }}</div>
          <div class="wf-sign-record__time">{{ item.signedTimeText }}</div>
          <v-icon size="18" color="primary">mdi-information-outline</v-icon>
        </button>
      </div>
      <div v-else="" class="wf-empty-state">Chưa có chữ ký hoàn tất.</div>
    </div>

    <v-dialog v-model="showDetailDialog" max-width="900">
      <v-card>
        <div class="wf-template-dialog-title">Chi tiết chữ kí số</div>
        <div class="wf-template-dialog-body wf-sign-detail-grid" v-if="activeDetail">
          <div class="wf-sign-detail-block">
            <h5>Thông tin người ký</h5>
            <div class="wf-info-row"><span class="label">Người ký</span><span class="value">{{ activeDetail.name }}</span></div>
            <div class="wf-info-row"><span class="label">Mã người ký</span><span class="value">{{ activeDetail.personId }}</span></div>
            <div class="wf-info-row"><span class="label">Phương thức</span><span class="value">{{ activeDetail.methodText }}</span></div>
            <div class="wf-info-row"><span class="label">Thời gian ký</span><span class="value">{{ activeDetail.signedTimeText }}</span></div>
          </div>

          <div class="wf-sign-detail-block">
            <h5>Thông tin chữ ký trên văn bản</h5>
            <div class="wf-info-row"><span class="label">Trang ký</span><span class="value">{{ activeDetail.pageText }}</span></div>
            <div class="wf-info-row"><span class="label">Kích thước</span><span class="value">{{ activeDetail.sizeText }}</span></div>
            <div class="wf-info-row"><span class="label">Vị trí (Rectangle)</span><span class="value">{{ activeDetail.rectangleText }}</span></div>
            <div class="wf-info-row"><span class="label">Bước / thứ tự ký</span><span class="value">{{ activeDetail.stepText }}</span></div>
          </div>

          <div class="wf-sign-detail-block wf-sign-detail-block--full">
            <h5>Thông tin chứng thư</h5>
            <div class="wf-info-row"><span class="label">Serial</span><span class="value">{{ activeDetail.certSerialText }}</span></div>
            <div class="wf-info-row"><span class="label">Nhà cung cấp</span><span class="value">{{ activeDetail.providerText }}</span></div>
            <div class="wf-info-row"><span class="label">Trạng thái lượt ký</span><span class="value">{{ activeDetail.statusText }}</span></div>
          </div>
        </div>
        <v-card-actions>
          <v-spacer>
          <v-btn class="wf-btn" variant="outlined" color="primary" @click="showDetailDialog = false">
            <v-icon start="">mdi-close</v-icon>
            Đóng
          </v-btn>
        </v-spacer></v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script>
	export default {
		name: "uc-request-sign-activity",
  props: {
    logs: { type: Array, default: function () { return []; } },
    signers: { type: Array, default: function () { return []; } },
    signBoxes: { type: Array, default: function () { return []; } },
    documentUrl: { type: String, default: "" },
    instanceName: { type: String, default: "" },
    defaultSignSystem: { type: String, default: "" },
    compact: { type: Boolean, default: false }
  },
  data: function () {
    return {
      showDetailDialog: false,
      activeDetail: null
    };
  },
  computed: {
    timelineRows: function () {
      var self = this;
      var logs = this.logs || [];
      var signers = this.signers || [];
      var rows = [];
      var waitingSigner = null;
      var pendingCount = 0;
      var signedCount = 0;
      var hasCompleted = false;
      var hasRejected = false;
      var i = 0;
      var item = null;

      for (i = 0; i < logs.length; i += 1) {
        item = logs[i];
        var action = String(item.ActionCode || "").toUpperCase();
        if (action === "INSTANCE_COMPLETED") hasCompleted = true;
        if (action === "REJECTED") hasRejected = true;
        rows.push({
          key: "log-" + item.LogID,
          title: self.resolveTimelineTitle(action),
          icon: self.resolveTimelineIcon(action),
          statusClass: self.resolveTimelineStatus(action),
          timeText: self.formatDateTime(item.CreateTime),
          actorText: item.UserID || "",
          subText: ""
        });
      }

      for (i = 0; i < signers.length; i += 1) {
        item = signers[i];
        if (String(item.Status || "").toUpperCase() === "WAITING" && !waitingSigner) waitingSigner = item;
        if (String(item.Status || "").toUpperCase() === "SIGNED" || item.SignedDate) signedCount += 1;
        else pendingCount += 1;
      }

      if (waitingSigner) {
        rows.push({
          key: "runtime-waiting-" + waitingSigner.SignerExecID,
          title: "Đang chờ ký",
          icon: "mdi-timer-sand",
          statusClass: "normal",
          timeText: "Đang xử lý",
          actorText: waitingSigner.ResolvedPersonName || waitingSigner.ResolvedPersonID || "-",
          subText: "Bước " + (waitingSigner.StepOrder || "-") + " · Thứ tự " + (waitingSigner.SignerOrder || "-")
        });
      }
      if (pendingCount > 0) {
        rows.push({
          key: "runtime-pending-count",
          title: "Chưa tới lượt ký",
          icon: "mdi-clock-outline",
          statusClass: "normal",
          timeText: "Còn " + pendingCount + " người",
          actorText: "",
          subText: "Đã ký " + signedCount + " / " + signers.length + " người"
        });
      }
      if (hasCompleted || (signers.length > 0 && pendingCount === 0 && !hasRejected)) {
        rows.push({
          key: "runtime-finished",
          title: "Văn bản đã hoàn thành",
          icon: "mdi-check-all",
          statusClass: "done",
          timeText: "Hoàn tất",
          actorText: "",
          subText: "Đã ký đủ " + signedCount + " người"
        });
      } else if (hasRejected) {
        rows.push({
          key: "runtime-rejected",
          title: "Văn bản đã bị từ chối",
          icon: "mdi-close-octagon-outline",
          statusClass: "rejected",
          timeText: "Kết thúc",
          actorText: "",
          subText: ""
        });
      }

      return rows.map(function (item) {
        return {
          key: item.key,
          title: item.title,
          icon: item.icon,
          statusClass: item.statusClass,
          timeText: item.timeText,
          actorText: item.actorText,
          subText: item.subText
        };
      });
    },
    signedRows: function () {
      var self = this;
      return (this.signers || [])
        .filter(function (item) {
          var status = String(item.Status || "").toUpperCase();
          return status === "SIGNED" || !!item.SignedDate;
        })
        .map(function (item) {
          return self.buildSignerDetail(item);
        })
        .sort(function (a, b) {
          return new Date(b.signedTimeRaw || 0).getTime() - new Date(a.signedTimeRaw || 0).getTime();
        });
    }
  },
  methods: {
    openSignatureDetail: function (item) {
      this.activeDetail = item;
      this.showDetailDialog = true;
    },
    downloadDocument: function () {
      if (!this.documentUrl) return;
      window.open(this.documentUrl, "_blank");
    },
    buildSignerDetail: function (signer) {
      var box = this.findBoxForSigner(signer);
      var pageNo = Number(box && box.PageNo ? box.PageNo : 0);
      var width = Number(box && box.BoxWidth ? box.BoxWidth : 0);
      var height = Number(box && box.BoxHeight ? box.BoxHeight : 0);
      var posX = Number(box && box.PosX ? box.PosX : 0);
      var posY = Number(box && box.PosY ? box.PosY : 0);
      var right = posX + width;
      var top = posY + height;
      return {
        key: "sg-" + signer.SignerExecID,
        name: signer.ResolvedPersonName || "Chưa xác định",
        personId: signer.ResolvedPersonID || "-",
        methodText: this.formatMethod(signer.SignMethod || this.defaultSignSystem),
        signedTimeText: this.formatDateTime(signer.SignedDate),
        signedTimeRaw: signer.SignedDate,
        pageText: pageNo > 0 ? String(pageNo) : "-",
        sizeText: width > 0 && height > 0 ? Math.round(width) + " × " + Math.round(height) + " pt" : "-",
        rectangleText: width > 0 && height > 0 ? "X: " + Math.round(posX) + ", Y: " + Math.round(posY) + ", Width: " + Math.round(width) + ", Height: " + Math.round(height) + " (R: " + Math.round(right) + ", T: " + Math.round(top) + ")" : "-",
        stepText: "Bước " + (signer.StepOrder || "-") + " · Thứ tự ký " + (signer.SignerOrder || "-"),
        certSerialText: signer.SignCertInfo || "-",
        providerText: this.formatMethod(signer.SignMethod || this.defaultSignSystem),
        statusText: this.formatSignerStatus(signer.Status || ""),
        boxId: box && box.InstanceSignBoxID ? box.InstanceSignBoxID : 0
      };
    },
    findBoxForSigner: function (signer) {
      var rows = this.signBoxes || [];
      var i = 0;
      var row = null;
      var stepOrder = Number(signer && signer.StepOrder || 0);
      var signerOrder = Number(signer && signer.SignerOrder || 0);
      for (i = 0; i < rows.length; i += 1) {
        row = rows[i];
        if (Number(row.StepOrder || 0) === stepOrder && Number(row.SignerOrder || 0) === signerOrder) return row;
      }
      return null;
    },
    formatDateTime: function (value) {
      if (!value) return "-";
      var dt = new Date(value);
      if (Number.isNaN(dt.getTime())) return value;
      var hh = String(dt.getHours()).padStart(2, "0");
      var mm = String(dt.getMinutes()).padStart(2, "0");
      var dd = String(dt.getDate()).padStart(2, "0");
      var mo = String(dt.getMonth() + 1).padStart(2, "0");
      var yyyy = dt.getFullYear();
      return hh + ":" + mm + " " + dd + "/" + mo + "/" + yyyy;
    },
    formatMethod: function (value) {
      var method = String(value || "").toLowerCase();
      var map = {
        smartca: "VNPT SmartCA",
        econtract: "VNPT eContract",
        otp_email: "OTP Email",
        otp_sms: "OTP SMS",
        image: "Ký ảnh"
      };
      return map[method] || value || "-";
    },
    formatSignerStatus: function (value) {
      var status = String(value || "").toUpperCase();
      var map = {
        PENDING: "Chưa tới lượt",
        WAITING: "Đang chờ ký",
        SIGNED: "Đã ký",
        REJECTED: "Từ chối",
        COMPLETED: "Hoàn tất"
      };
      return map[status] || status || "-";
    },
    resolveTimelineTitle: function (action) {
      var map = {
        INSTANCE_CREATED: "Khởi tạo văn bản",
        SIGNED: "Đã ký",
        REJECTED: "Từ chối ký",
        INSTANCE_COMPLETED: "Hoàn thành"
      };
      return map[action] || "Cập nhật";
    },
    resolveTimelineIcon: function (action) {
      var map = {
        INSTANCE_CREATED: "mdi-file-plus-outline",
        SIGNED: "mdi-check-circle-outline",
        REJECTED: "mdi-close-circle-outline",
        INSTANCE_COMPLETED: "mdi-flag-checkered"
      };
      return map[action] || "mdi-history";
    },
    resolveTimelineStatus: function (action) {
      if (action === "REJECTED") return "rejected";
      if (action === "SIGNED" || action === "INSTANCE_COMPLETED") return "done";
      return "normal";
    }
  }
	}
</script>
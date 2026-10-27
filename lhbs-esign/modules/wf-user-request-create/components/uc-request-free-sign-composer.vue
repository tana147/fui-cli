<template>
	<div class="wf-free-sign-composer">
    <div class="wf-free-sign-layout">
      <div class="wf-free-sign-workspace">
        <div class="wf-free-sign-stage-layout">
          <uc-free-sign-sidebar :active-page="activePage" :max-page="pageCount"
            :visible-page-options="visiblePageOptions" :page-thumbnails="pageThumbnails" @prev-page="goPrevPage"
            @next-page="goNextPage" @set-active-page="setActivePage"></uc-free-sign-sidebar>

          <uc-free-sign-stage ref="stageRef" :preview-file-url="previewFileUrl" :sign-boxes="form.signBoxes || []"
            :active-page="activePage" :selected-box-index="selectedBoxIndex" :zoom-percent="zoomPercent"
            :zoom-presets="zoomPresets" :box-style="boxStyle" :box-label="boxLabel" @canvas-click="onCanvasClick"
            @select-box="selectBox" @open-box-dialog="openBoxDialog" @box-mouse-down="onBoxMouseDown"
            @box-touch-start="onBoxTouchStart" @remove-box="removeBox"
            @resize-handle-mouse-down="onResizeHandleMouseDown" @resize-handle-touch-start="onResizeHandleTouchStart"
            @zoom-out="zoomOut" @zoom-in="zoomIn" @fit-to-viewport="fitToViewport" @set-zoom-preset="setZoomPreset"
            @update-page-count="updatePageCount" @update-active-page="syncActivePageFromViewport"
            @update-thumbnails="updateThumbnails" @wheel-zoom-in="zoomIn" @wheel-zoom-out="zoomOut">
          </uc-free-sign-stage>
        </div>
      </div>

      <uc-free-sign-box-list :form="form" :categories="categories" :execution-engine-options="executionEngineOptions"
        :contract-provider-options="contractProviderOptions" :priority-options="priorityOptions"
        :effective-engine="effectiveEngine" :upload-label="uploadLabel" :upload-sub-label="uploadSubLabel"
        :sign-boxes="form.signBoxes" :box-count="boxCount" :selected-box-index="selectedBoxIndex"
        :format-signer-method="formatSignerMethod" @open-file-dialog="openFileDialog" @select-box="selectBox"
        @open-box-dialog="openBoxDialog" @remove-box="removeBox"></uc-free-sign-box-list>
    </div>

    <v-dialog v-model="boxDialog" max-width="560">
      <v-card>
        <v-card-title class="wf-dialog-title">Gán người ký cho box</v-card-title>
        <v-card-text>
          <div class="wf-request-form-grid wf-request-form-grid--2">
            <v-select v-model="boxDialogForm.PageNo" :items="visiblePageOptions" label="Trang" variant="outlined"
              density="compact" />
            <v-text-field v-model.number="boxDialogForm.SignerOrder" type="number" min="1" label="Thứ tự ký"
              variant="outlined" density="compact" />
            <v-select v-model="boxDialogSignerKey" :items="signerItems" item-title="title" item-value="value"
              label="Người ký" variant="outlined" density="compact" class="wf-request-span-2" />
            <v-text-field v-model="boxDialogForm.LabelText" label="Nhãn hiển thị trên box" variant="outlined"
              density="compact" class="wf-request-span-2" />
          </div>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="closeBoxDialog">Hủy</v-btn>
          <v-btn class="wf-btn" variant="outlined" color="primary" @click="applyBoxDialog">
            <v-icon start size="16">mdi-content-save-outline</v-icon>
            Lưu box
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script>
	export default {
		name: "uc-request-free-sign-composer",
  props: {
    form: { type: Object, default: function () { return { signBoxes: [], signers: [] }; } },
    signerProfiles: { type: Array, default: function () { return []; } },
    roleOptions: { type: Array, default: function () { return []; } },
    signMethodOptions: { type: Array, default: function () { return []; } },
    previewFileUrl: { type: String, default: "" },
    categories: { type: Array, default: function () { return []; } },
    executionEngineOptions: { type: Array, default: function () { return []; } },
    contractProviderOptions: { type: Array, default: function () { return []; } },
    priorityOptions: { type: Array, default: function () { return []; } },
    effectiveEngine: { type: String, default: "SMARTCA" },
    uploadLabel: { type: String, default: "" },
    uploadSubLabel: { type: String, default: "" }
  },
  emits: ["open-file-dialog"],
  data: function () {
    return {
      activePage: 1,
      pageInput: 1,
      pageCount: 1,
      pageThumbnails: [],
      selectedBoxIndex: -1,
      selectedSignerKey: "",
      boxDialog: false,
      boxDialogIndex: -1,
      boxDialogSignerKey: "",
      boxDialogForm: {
        PageNo: 1,
        SignerOrder: null,
        LabelText: ""
      },
      zoomScale: 1,
      minZoom: 0.75,
      maxZoom: 2.5,
      zoomPresets: [75, 100, 125, 150, 200],
      baseCanvasWidth: 980,
      dragState: {
        isDragging: false,
        isPending: false,
        boxIndex: -1,
        startX: 0,
        startY: 0,
        offsetX: 0,
        offsetY: 0
      },
      resizeState: {
        isResizing: false,
        boxIndex: -1,
        startX: 0,
        startY: 0,
        startWidth: 18,
        startHeight: 8
      },
      lastDragEndAt: 0
    };
  },
  mounted: function () {
    this.ensureBoxesArray();
    this.pageCount = this.getMaxPageFromBoxes();
    this.fitToViewport();
    this.pageInput = this.activePage;
    window.addEventListener("mousemove", this.onGlobalMouseMove);
    window.addEventListener("mouseup", this.onGlobalMouseUp);
    window.addEventListener("touchmove", this.onGlobalTouchMove, { passive: false });
    window.addEventListener("touchend", this.onGlobalTouchEnd);
    window.addEventListener("touchcancel", this.onGlobalTouchEnd);
    window.addEventListener("resize", this.fitToViewport);
  },
  beforeUnmount: function () {
    window.removeEventListener("mousemove", this.onGlobalMouseMove);
    window.removeEventListener("mouseup", this.onGlobalMouseUp);
    window.removeEventListener("touchmove", this.onGlobalTouchMove);
    window.removeEventListener("touchend", this.onGlobalTouchEnd);
    window.removeEventListener("touchcancel", this.onGlobalTouchEnd);
    window.removeEventListener("resize", this.fitToViewport);
  },
  computed: {
    boxCount: function () {
      return this.form.signBoxes && Array.isArray(this.form.signBoxes) ? this.form.signBoxes.length : 0;
    },
    visiblePageOptions: function () {
      var highest = Number(this.pageCount || 1);
      var output = [];
      var i = 0;
      if (!highest || highest < 1) highest = 1;
      for (i = 1; i <= highest; i += 1) output.push(i);
      return output;
    },
    currentBox: function () {
      if (this.selectedBoxIndex < 0 || !this.form.signBoxes) return null;
      return this.form.signBoxes[this.selectedBoxIndex] || null;
    },
    signerItems: function () {
      var items = [];
      var i = 0;
      for (i = 0; i < (this.signerProfiles || []).length; i += 1) {
        if (!this.resolveProfileSignerValue(this.signerProfiles[i])) continue;
        items.push({
          value: String(this.signerProfiles[i].SignerProfileID || i + 1),
          title: (this.signerProfiles[i].FullName || this.signerProfiles[i].EmployeeCode || this.signerProfiles[i].Email || "Người ký") +
            (this.signerProfiles[i].CertSerial ? (" · CTS " + this.signerProfiles[i].CertSerial) : "")
        });
      }
      return items;
    },
    zoomPercent: function () {
      return Math.round((this.zoomScale || 1) * 100);
    }
  },
  methods: {
    openFileDialog: function () {
      this.$emit("open-file-dialog");
    },
    ensureBoxesArray: function () {
      if (!this.form.signBoxes || !Array.isArray(this.form.signBoxes)) this.form.signBoxes = [];
    },
    usesPdfPageCount: function () {
      return !!this.previewFileUrl;
    },
    getMaxPageFromBoxes: function () {
      var highest = 1;
      var i = 0;
      for (i = 0; i < (this.form.signBoxes || []).length; i += 1) {
        highest = Math.max(highest, Number(this.form.signBoxes[i].PageNo || 1) || 1);
      }
      return highest;
    },
    fitToViewport: function () {
      var viewport = this.$refs.stageRef && this.$refs.stageRef.$refs ? this.$refs.stageRef.$refs.viewport : null;
      if (!viewport || !viewport.clientWidth) return;
      this.zoomScale = this.clampPercent((viewport.clientWidth - 32) / this.baseCanvasWidth, this.minZoom, this.maxZoom);
    },
    setZoomPreset: function (preset) {
      this.zoomScale = this.clampPercent(Number(preset || 100) / 100, this.minZoom, this.maxZoom);
    },
    zoomIn: function () {
      this.zoomScale = this.clampPercent((this.zoomScale || 1) + 0.1, this.minZoom, this.maxZoom);
    },
    zoomOut: function () {
      this.zoomScale = this.clampPercent((this.zoomScale || 1) - 0.1, this.minZoom, this.maxZoom);
    },
    setActivePage: function (pageNo) {
      var normalized = Number(pageNo || 1);
      var stage = null;
      if (!normalized || normalized < 1) normalized = 1;
      if (normalized > Number(this.pageCount || 1)) normalized = Number(this.pageCount || 1);
      this.activePage = normalized;
      this.pageInput = normalized;
      stage = this.$refs.stageRef;
      if (stage && stage.scrollToPage) {
        this.$nextTick(function () {
          stage.scrollToPage(normalized, true);
        });
      }
    },
    updatePageCount: function (value) {
      var normalized = Number(value || 1);
      if (!normalized || normalized < 1) normalized = 1;
      this.pageCount = normalized;
      if (this.activePage > normalized) this.setActivePage(normalized);
    },
    updateThumbnails: function (rows) {
      this.pageThumbnails = Array.isArray(rows) ? rows : [];
    },
    syncActivePageFromViewport: function (pageNo) {
      var normalized = Number(pageNo || 1);
      if (!normalized || normalized < 1) normalized = 1;
      this.activePage = normalized;
      this.pageInput = normalized;
    },
    goPrevPage: function () {
      this.setActivePage(Math.max(1, Number(this.activePage || 1) - 1));
    },
    goNextPage: function () {
      this.setActivePage(Math.min(Number(this.pageCount || 1), Number(this.activePage || 1) + 1));
    },
    onCanvasClick: function (pageNo, event) {
      var rect = null;
      var x = 0;
      var y = 0;
      if (Date.now() - Number(this.lastDragEndAt || 0) < 220) return;
      rect = this.getStageRect(pageNo);
      if (!rect) return;
      x = ((event.clientX - rect.left) / rect.width) * 100;
      y = ((event.clientY - rect.top) / rect.height) * 100;
      this.addBox(x, y, pageNo);
    },
    addBox: function (x, y, pageNo) {
      var box = this.buildNewBox(x, y, pageNo);
      this.form.signBoxes.push(box);
      this.syncBoxOrder();
      if (!this.usesPdfPageCount()) this.pageCount = Math.max(this.pageCount, Number(box.PageNo || 1) || 1);
      this.selectBox(this.form.signBoxes.length - 1);
      this.openBoxDialog(this.form.signBoxes.length - 1);
    },
    buildNewBox: function (x, y, pageNo) {
      return {
        BoxOrder: this.form.signBoxes.length + 1,
        PageNo: Number(pageNo || this.activePage || 1) || 1,
        PosX: this.clampPercent(x, 0, 92),
        PosY: this.clampPercent(y, 0, 94),
        Width: 18,
        Height: 8,
        StepOrder: 1,
        SignerOrder: null,
        SignerType: "USER",
        SignerValue: "",
        PersonName: "",
        DepartmentName: "",
        SignMethod: "SmartCA (Ký số)",
        ExecutionEngine: this.form.executionEngine || "SMARTCA",
        ContractProvider: this.form.contractProvider || "",
        LabelText: ""
      };
    },
    selectBox: function (absoluteIndex, options) {
      var self = this;
      var shouldNavigate = !options || options.navigate !== false;
      this.selectedBoxIndex = absoluteIndex;
      if (absoluteIndex >= 0 && this.form.signBoxes && this.form.signBoxes[absoluteIndex]) {
        if (shouldNavigate) {
          this.setActivePage(Number(this.form.signBoxes[absoluteIndex].PageNo || 1));
          window.setTimeout(function () {
            self.scrollSelectedBoxIntoView();
          }, 140);
        }
      }
      this.refreshSelectedSignerKey();
    },
    scrollSelectedBoxIntoView: function () {
      var stage = this.$refs.stageRef;
      if (!stage || !stage.scrollToBox || this.selectedBoxIndex < 0) return;
      stage.scrollToBox(this.selectedBoxIndex);
    },
    removeBox: function (absoluteIndex) {
      if (absoluteIndex < 0 || !this.form.signBoxes || !this.form.signBoxes[absoluteIndex]) return;
      this.form.signBoxes.splice(absoluteIndex, 1);
      this.syncBoxOrder();
      if (!this.usesPdfPageCount()) this.pageCount = Math.max(1, this.getMaxPageFromBoxes());
      if (!this.form.signBoxes.length) {
        this.selectedBoxIndex = -1;
        this.selectedSignerKey = "";
        return;
      }
      this.selectBox(Math.max(0, absoluteIndex - 1));
    },
    syncBoxOrder: function () {
      var i = 0;
      for (i = 0; i < this.form.signBoxes.length; i += 1) this.form.signBoxes[i].BoxOrder = i + 1;
    },
    boxStyle: function (box) {
      return {
        left: this.clampPercent(box.PosX, 0, 92) + "%",
        top: this.clampPercent(box.PosY, 0, 94) + "%",
        width: this.clampPercent(box.Width, 8, 60) + "%",
        height: this.clampPercent(box.Height, 4, 30) + "%"
      };
    },
    boxLabel: function (box, absoluteIndex) {
      var signerName = box.LabelText || box.PersonName || box.SignerValue || "Chưa gán";
      return "#" + (absoluteIndex + 1) + " - " + signerName;
    },
    openBoxDialog: function (absoluteIndex) {
      var row = this.form.signBoxes && this.form.signBoxes[absoluteIndex] ? this.form.signBoxes[absoluteIndex] : null;
      var matchedProfile = null;
      if (!row) return;
      this.selectBox(absoluteIndex, { navigate: false });
      this.boxDialogIndex = absoluteIndex;
      this.boxDialogForm = {
        PageNo: row.PageNo || 1,
        SignerOrder: row.SignerOrder || null,
        LabelText: row.LabelText || ""
      };
      if (row.SignerValue) {
        matchedProfile = (this.signerProfiles || []).find(function (item) {
          var value = "";
          if (!item) return false;
          if (item.EmployeeCode) value = String(item.EmployeeCode).trim();
          else if (item.Email) value = String(item.Email).trim();
          else if (item.LegacyUserID !== null && typeof item.LegacyUserID !== "undefined") value = String(item.LegacyUserID).trim();
          return value && value === String(row.SignerValue || "").trim();
        });
      }
      this.boxDialogSignerKey = matchedProfile ? String(matchedProfile.SignerProfileID) : "";
      this.boxDialog = true;
    },
    closeBoxDialog: function () {
      this.boxDialog = false;
      this.boxDialogIndex = -1;
      this.boxDialogSignerKey = "";
    },
    applyBoxDialog: function () {
      var row = this.form.signBoxes && this.form.signBoxes[this.boxDialogIndex] ? this.form.signBoxes[this.boxDialogIndex] : null;
      if (!row) return;
      if (!this.boxDialogSignerKey) {
        if (showToast && showToast.error) showToast.error("Vui lòng chọn người ký trước khi lưu box.");
        return;
      }
      row.PageNo = Number(this.boxDialogForm.PageNo || 1);
      row.LabelText = this.boxDialogForm.LabelText || "";
      this.applySignerByKey(this.boxDialogSignerKey, row);
      if (this.boxDialogForm.SignerOrder) row.SignerOrder = Number(this.boxDialogForm.SignerOrder) || row.SignerOrder;
      if (!this.usesPdfPageCount()) this.pageCount = Math.max(this.pageCount, Number(row.PageNo || 1) || 1);
      this.setActivePage(Number(row.PageNo || 1));
      this.closeBoxDialog();
    },
    onBoxMouseDown: function (absoluteIndex, event) {
      this.startDraggingBox(absoluteIndex, this.getClientPoint(event));
    },
    onBoxTouchStart: function (absoluteIndex, event) {
      this.startDraggingBox(absoluteIndex, this.getClientPoint(event));
    },
    onResizeHandleMouseDown: function (absoluteIndex, event) {
      this.startResizingBox(absoluteIndex, this.getClientPoint(event));
    },
    onResizeHandleTouchStart: function (absoluteIndex, event) {
      this.startResizingBox(absoluteIndex, this.getClientPoint(event));
    },
    startDraggingBox: function (absoluteIndex, point) {
      var row = null;
      var stageRect = null;
      var boxLeft = 0;
      var boxTop = 0;
      if (absoluteIndex < 0 || !point) return;
      row = this.form.signBoxes[absoluteIndex];
      if (!row) return;
      stageRect = this.getStageRect(row.PageNo || this.activePage || 1);
      if (!stageRect) return;
      this.selectBox(absoluteIndex, { navigate: false });
      boxLeft = (Number(row.PosX || 0) / 100) * stageRect.width;
      boxTop = (Number(row.PosY || 0) / 100) * stageRect.height;
      this.dragState.isPending = true;
      this.dragState.isDragging = false;
      this.dragState.boxIndex = absoluteIndex;
      this.dragState.startX = point.clientX;
      this.dragState.startY = point.clientY;
      this.dragState.offsetX = (((point.clientX - stageRect.left) - boxLeft) / stageRect.width) * 100;
      this.dragState.offsetY = (((point.clientY - stageRect.top) - boxTop) / stageRect.height) * 100;
    },
    startResizingBox: function (absoluteIndex, point) {
      var row = absoluteIndex >= 0 && this.form.signBoxes ? this.form.signBoxes[absoluteIndex] : null;
      if (!row || !point) return;
      this.selectBox(absoluteIndex, { navigate: false });
      this.resizeState.isResizing = true;
      this.resizeState.boxIndex = absoluteIndex;
      this.resizeState.startX = point.clientX;
      this.resizeState.startY = point.clientY;
      this.resizeState.startWidth = Number(row.Width || 18);
      this.resizeState.startHeight = Number(row.Height || 8);
    },
    onGlobalMouseMove: function (event) {
      this.updateDraggingBox(event);
      this.updateResizingBox(event);
    },
    onGlobalTouchMove: function (event) {
      this.updateDraggingBox(event);
      this.updateResizingBox(event);
      if ((this.dragState.isDragging || this.resizeState.isResizing) && event && event.cancelable) event.preventDefault();
    },
    updateDraggingBox: function (event) {
      var point = this.getClientPoint(event);
      var row = null;
      var stageRect = null;
      var nextX = 0;
      var nextY = 0;
      var maxX = 92;
      var maxY = 94;
      if ((!this.dragState.isDragging && !this.dragState.isPending) || this.dragState.boxIndex < 0 || !point) return;
      if (this.dragState.isPending) {
        if (Math.abs(point.clientX - this.dragState.startX) < 3 && Math.abs(point.clientY - this.dragState.startY) < 3) return;
        this.dragState.isPending = false;
        this.dragState.isDragging = true;
      }
      if (!this.dragState.isDragging) return;
      row = this.form.signBoxes[this.dragState.boxIndex];
      if (!row) return;
      stageRect = this.getStageRect(row.PageNo || this.activePage || 1);
      if (!stageRect) return;
      nextX = (((point.clientX - stageRect.left) / stageRect.width) * 100) - this.dragState.offsetX;
      nextY = (((point.clientY - stageRect.top) / stageRect.height) * 100) - this.dragState.offsetY;
      maxX = 100 - Number(row.Width || 8);
      maxY = 100 - Number(row.Height || 4);
      row.PosX = this.clampPercent(nextX, 0, maxX < 0 ? 0 : maxX);
      row.PosY = this.clampPercent(nextY, 0, maxY < 0 ? 0 : maxY);
    },
    updateResizingBox: function (event) {
      var point = this.getClientPoint(event);
      var row = null;
      var stageRect = null;
      var deltaX = 0;
      var deltaY = 0;
      if (!this.resizeState.isResizing || this.resizeState.boxIndex < 0 || !point) return;
      row = this.form.signBoxes[this.resizeState.boxIndex];
      if (!row) return;
      stageRect = this.getStageRect(row.PageNo || this.activePage || 1);
      if (!stageRect) return;
      deltaX = ((point.clientX - this.resizeState.startX) / stageRect.width) * 100;
      deltaY = ((point.clientY - this.resizeState.startY) / stageRect.height) * 100;
      row.Width = this.clampPercent(this.resizeState.startWidth + deltaX, 8, 60);
      row.Height = this.clampPercent(this.resizeState.startHeight + deltaY, 4, 30);
    },
    onGlobalMouseUp: function () {
      this.stopDraggingBox();
      this.stopResizingBox();
    },
    onGlobalTouchEnd: function () {
      this.stopDraggingBox();
      this.stopResizingBox();
    },
    stopDraggingBox: function () {
      if (!this.dragState.isDragging && !this.dragState.isPending) return;
      this.dragState.isPending = false;
      this.dragState.isDragging = false;
      this.dragState.boxIndex = -1;
      this.lastDragEndAt = Date.now();
    },
    stopResizingBox: function () {
      if (!this.resizeState.isResizing) return;
      this.resizeState.isResizing = false;
      this.resizeState.boxIndex = -1;
      this.lastDragEndAt = Date.now();
    },
    getStageRect: function (pageNo) {
      return this.$refs.stageRef && this.$refs.stageRef.getPageRect ? this.$refs.stageRef.getPageRect(pageNo || this.activePage || 1) : null;
    },
    getClientPoint: function (event) {
      var touch = null;
      if (!event) return null;
      if (event.touches && event.touches.length) {
        touch = event.touches[0];
        return { clientX: Number(touch.clientX || 0), clientY: Number(touch.clientY || 0) };
      }
      if (event.changedTouches && event.changedTouches.length) {
        touch = event.changedTouches[0];
        return { clientX: Number(touch.clientX || 0), clientY: Number(touch.clientY || 0) };
      }
      return { clientX: Number(event.clientX || 0), clientY: Number(event.clientY || 0) };
    },
    clampPercent: function (value, min, max) {
      var number = Number(value);
      if (isNaN(number)) number = min;
      if (number < min) number = min;
      if (number > max) number = max;
      return Math.round(number * 100) / 100;
    },
    refreshSelectedSignerKey: function () {
      var row = this.currentBox;
      this.selectedSignerKey = row && row.SignerValue ? String(row.SignerValue) : "";
    },
    resolveProfileSignerValue: function (profile) {
      if (!profile) return "";
      if (profile.EmployeeCode) return String(profile.EmployeeCode).trim();
      if (profile.Email) return String(profile.Email).trim();
      if (profile.LegacyUserID !== null && typeof profile.LegacyUserID !== "undefined" && String(profile.LegacyUserID).trim() !== "") return String(profile.LegacyUserID).trim();
      return "";
    },
    applySignerByKey: function (value, targetRow) {
      var profile = null;
      var profileId = Number(value || 0);
      var row = targetRow || this.currentBox;
      if (!row || !profileId) return;
      profile = (this.signerProfiles || []).find(function (item) { return Number(item.SignerProfileID || 0) === profileId; });
      if (!profile) return;
      row.StepOrder = row.StepOrder || 1;
      row.SignerType = "USER";
      row.SignerValue = this.resolveProfileSignerValue(profile);
      row.SignerOrder = this.resolveSignerOrder(row.SignerValue);
      row.PersonName = profile.FullName || "";
      row.DepartmentName = profile.DepartmentName || "";
      row.SignMethod = "SmartCA (Ký số)";
      row.ExecutionEngine = this.form.executionEngine || "SMARTCA";
      row.ContractProvider = this.form.contractProvider || "";
      if (!row.LabelText) row.LabelText = row.PersonName || row.SignerValue;
      this.selectedSignerKey = String(profileId);
    },
    resolveSignerOrder: function (signerValue) {
      var key = String(signerValue || "").trim().toUpperCase();
      var orderMap = {};
      var order = 1;
      var i = 0;
      if (!key) return null;
      for (i = 0; i < (this.form.signBoxes || []).length; i += 1) {
        var rowKey = String(this.form.signBoxes[i].SignerValue || "").trim().toUpperCase();
        if (!rowKey) continue;
        if (!orderMap[rowKey]) {
          orderMap[rowKey] = order;
          order += 1;
        }
      }
      if (orderMap[key]) return orderMap[key];
      return order;
    },
    formatSignerMethod: function (value) {
      var raw = String(value || "").toLowerCase();
      if (raw.indexOf("smartca") >= 0) return "SmartCA";
      if (raw.indexOf("otp email") >= 0) return "OTP Email";
      if (raw.indexOf("otp sms") >= 0) return "OTP SMS";
      if (raw.indexOf("econtract") >= 0) return "eContract";
      return value || "-";
    }
  },
  watch: {
    previewFileUrl: function () {
      this.$nextTick(this.fitToViewport);
    },
    activePage: function (value) {
      this.pageInput = Number(value || 1);
    },
    "form.signBoxes": {
      deep: true,
      handler: function () {
        this.pageCount = Math.max(this.pageCount, this.getMaxPageFromBoxes());
        if (this.selectedBoxIndex >= 0 && this.form.signBoxes[this.selectedBoxIndex]) this.refreshSelectedSignerKey();
      }
    }
  }
	}
</script>
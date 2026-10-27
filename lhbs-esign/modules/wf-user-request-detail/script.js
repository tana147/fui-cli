var wfRequestDetailExternalMixin = {
  methods: {
    shouldSyncEcontract: function () {
      var engine = String(this.overview.ExecutionEngine || "").toUpperCase();
      var provider = String(this.overview.ContractProvider || "").toUpperCase();
      if (provider === "AMIS_WESIGN" && !!this.resolveWeSignDocumentId()) return true;
      if (provider === "VNPT_ECONTRACT" || this.resolveEcontractHopDongId() > 0) return true;
      return engine === "ECONTRACT" && this.canSyncCurrentEcontractProvider();
    },
    canSyncCurrentEcontractProvider: function () {
      var provider = String(this.resolveOverviewContractProvider() || "").toUpperCase();
      return provider === "VNPT_ECONTRACT" || provider === "AMIS_WESIGN";
    },
    extractEcontractTaggedId: function (text) {
      var raw = String(text || "");
      var match = raw.match(/\[eContractHopDongID:(\d+)\]/i);
      return match && match[1] ? (Number(match[1]) || 0) : 0;
    },
    extractWeSignTaggedId: function (text) {
      var raw = String(text || "");
      var match = raw.match(/\[eContractDocumentID:([0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})\]/i);
      return match && match[1] ? String(match[1]).trim() : "";
    },
    resolveEcontractHopDongId: function () {
      var id = Number(this.overview.ExternalContractID || 0);
      if (id > 0) return id;
      id = this.extractEcontractTaggedId(this.overview.Description || "");
      if (id > 0) return id;
      return this.extractEcontractTaggedId(this.overview.ReferenceCode || "");
    },
    resolveWeSignDocumentId: function () {
      var created = this.extractCreatedLogConfig() || {};
      var documentId = this.extractWeSignTaggedId(this.overview.Description || "");
      if (documentId) return documentId;
      documentId = this.extractWeSignTaggedId(this.overview.ReferenceCode || "");
      if (documentId) return documentId;
      documentId = this.extractWeSignTaggedId(created.Description || "");
      if (documentId) return documentId;
      return this.extractWeSignTaggedId(created.ReferenceCode || "");
    },
    isExternalDocumentCompleted: function () {
      var provider = this.resolveOverviewContractProvider();
      if (provider === "AMIS_WESIGN") {
        return /hoan thanh|hoàn thành|completed|done|success|signed/i.test(String(this.overview.ExternalSignStatusText || this.overview.ExternalContractStatusText || ""));
      }
      return this.isEcontractCompletedStatus({
        contractStatusCode: this.overview.ExternalContractStatusCode,
        signStatusCode: this.overview.ExternalSignStatusCode
      });
    },
    resolveEcontractProxyBase: function () {
      var base = "";
      try {
        if (typeof window !== "undefined" && window && window.__WF_ECONTRACT_PROXY_BASE__) base = String(window.__WF_ECONTRACT_PROXY_BASE__ || "").trim();
      } catch (e) {}
      if (!base) {
        try {
          if (typeof localStorage !== "undefined" && localStorage) base = String(localStorage.getItem("WF_ECONTRACT_PROXY_BASE") || "").trim();
        } catch (e2) {}
      }
      if (!base) base = "https://ca-uat.iotsoftvn.com";
      return base.replace(/\/+$/, "");
    },
    resolveEcontractApiKey: function () {
      var key = "";
      try {
        if (typeof window !== "undefined" && window && window.__WF_ECONTRACT_APIKEY__) key = String(window.__WF_ECONTRACT_APIKEY__ || "").trim();
      } catch (e) {}
      if (!key) {
        try {
          if (typeof localStorage !== "undefined" && localStorage) key = String(localStorage.getItem("WF_ECONTRACT_APIKEY") || "").trim();
        } catch (e2) {}
      }
      if (!key) key = "eGFjLXRodWMtdHUtbGh1LWVkdS12bkAyMDI1QGZ1aS52bg==";
      return key;
    },
    resolveEcontractUrl: function (template, routeValue) {
      var path = String(template || "");
      var base = this.resolveEcontractProxyBase();
      var normalizedRouteValue = routeValue == null ? "" : String(routeValue).trim();
      if (path.indexOf("{hopDongId}") >= 0) path = path.replace("{hopDongId}", String(Number(routeValue || 0)));
      if (path.indexOf("{documentId}") >= 0) path = path.replace("{documentId}", normalizedRouteValue);
      if (!path) return base;
      if (path.indexOf("http://") === 0 || path.indexOf("https://") === 0) return path;
      if (path.charAt(0) !== "/") path = "/" + path;
      return base + path;
    },
    extractEcontractResponseObject: function (response) {
      if (!response) return null;
      if (response.object && typeof response.object === "object") return response.object;
      if (response.Object && typeof response.Object === "object") return response.Object;
      if (response.data && typeof response.data === "object") return this.extractEcontractResponseObject(response.data) || response.data;
      return response;
    },
    extractEcontractPrimaryObject: function (response) {
      var root = this.extractEcontractResponseObject(response);
      if (Array.isArray(root)) return root.length ? (root[0] || null) : null;
      return root;
    },
    extractEcontractTokenFromLoginResponse: function (response) {
      var obj = this.extractEcontractResponseObject(response) || {};
      return String(obj.accessToken || obj.AccessToken || "").trim();
    },
    loginEcontract: async function () {
      var now = Date.now();
      var response = null;
      var token = "";
      if (this.econtractAuthCache && this.econtractAuthCache.token && Number(this.econtractAuthCache.expiredAt || 0) > now) return this.econtractAuthCache.token;
      response = await this.econtractRequest("POST", this.eContractApiMap.authLogin, {}, "");
      token = this.extractEcontractTokenFromLoginResponse(response);
      if (!token) throw new Error("Đăng nhập eContract thành công nhưng không lấy được access token.");
      this.econtractAuthCache = { token: token, expiredAt: Date.now() + (50 * 60 * 1000) };
      return token;
    },
    econtractRequest: function (method, url, payload, token) {
      var requestUrl = String(url || "").trim();
      var requestMethod = String(method || "POST").toUpperCase();
      var cacheKey = "_ts=" + String(Date.now());
      var headers = {
        "Content-Type": "application/json; charset=utf-8",
        "X-API-KEY": this.resolveEcontractApiKey(),
        "Cache-Control": "no-cache, no-store, must-revalidate",
        Pragma: "no-cache"
      };
      if (requestUrl && requestUrl.indexOf("http://") !== 0 && requestUrl.indexOf("https://") !== 0) {
        if (requestUrl.charAt(0) !== "/") requestUrl = "/" + requestUrl;
        requestUrl = this.resolveEcontractProxyBase() + requestUrl;
      }
      if (requestMethod === "GET") requestUrl += (requestUrl.indexOf("?") >= 0 ? "&" : "?") + cacheKey;
      if (token) headers.Authorization = "Bearer " + token;
      return $.ajax({
        type: requestMethod,
        url: requestUrl,
        headers: headers,
        dataType: "json",
        cache: false,
        crossDomain: true,
        contentType: "application/json; charset=utf-8",
        data: requestMethod === "GET" ? null : JSON.stringify(payload || {})
      });
    },
    mapEcontractContractStatusText: function (statusId) {
      var value = Number(statusId || 0);
      var map = { 1: "Bản nháp", 2: "Thẩm định", 3: "Đàm phán", 4: "Chờ ký", 5: "Ký lỗi", 6: "Cảnh báo", 7: "Đã hủy", 8: "Lỗi chứng thực", 9: "Hoàn thành", 10: "Có hiệu lực", 11: "Đã hết hạn", 12: "Thanh lý trước thời hạn", 13: "Thanh lý theo thời hạn", 14: "Hợp đồng đã chấm dứt", 15: "Quá hạn ký", 16: "Quá hạn thẩm định", 17: "Quá hạn đàm phán", 18: "Chờ chứng thực" };
      return map[value] || (value > 0 ? ("Trạng thái #" + value) : "");
    },
    mapEcontractSignStatusText: function (statusId) {
      var value = Number(statusId || 0);
      var map = { 1: "Khởi tạo", 2: "Đang xử lý", 3: "Chờ ký", 4: "Ký lỗi", 5: "Từ chối", 6: "Hủy", 7: "Chờ ký", 8: "Hoàn thành" };
      return map[value] || (value > 0 ? ("Trạng thái ký #" + value) : "");
    },
    extractEcontractStatusSummary: function (response) {
      var root = this.extractEcontractPrimaryObject(response) || {};
      var contractStatusId = Number(root.trangThaiHdId || root.TRANGTHAI_HD_ID || root.trangThai || 0) || 0;
      var signStatusId = Number(root.trangThaiKyId || root.TRANGTHAI_KY_ID || 0) || 0;
      return {
        contractStatusCode: contractStatusId > 0 ? String(contractStatusId) : "",
        contractStatusText: String(root.TRANGTHAI_HD || root.TRANGTHAI_TEN || this.mapEcontractContractStatusText(contractStatusId) || "").trim(),
        signStatusCode: signStatusId > 0 ? String(signStatusId) : "",
        signStatusText: String(root.TRANGTHAI_KY_FE || this.mapEcontractSignStatusText(signStatusId) || "").trim()
      };
    },
    mapWeSignStatusText: function (value) {
      var raw = String(value || "").trim();
      var upper = raw.toUpperCase();
      if (!upper) return "";
      if (/COMPLETE|COMPLETED|DONE|FINISH|SUCCESS|SIGNED|APPROVED|HOAN.?TAT/.test(upper)) return "Hoàn thành";
      if (/REJECT|DECLIN|REFUSE|TU.?CHOI/.test(upper)) return "Từ chối";
      if (/CANCEL|CANCELED|CANCELLED|VOID|HUY/.test(upper)) return "Đã hủy";
      if (/PROCESS|PROGRESS|SIGNING|EXECUTING|IN_PROGRESS|RUNNING/.test(upper)) return "Đang ký";
      if (/WAIT|PENDING|NEW|CREATE|INIT|READY/.test(upper)) return "Chờ ký";
      return raw;
    },
    extractWeSignStatusSummary: function (response) {
      var root = this.extractEcontractResponseObject(response) || response || {};
      var primary = this.extractEcontractPrimaryObject(root) || root || {};
      var rawStatus = this.findValueByKeysDeep(primary, function (key, value) { return /status|state/i.test(String(key || "")) && (typeof value === "string" || typeof value === "number"); });
      var rawSignStatus = this.findValueByKeysDeep(primary, function (key, value) { return /sign.*status|status.*sign/i.test(String(key || "")) && (typeof value === "string" || typeof value === "number"); });
      var statusText = this.mapWeSignStatusText(rawSignStatus || rawStatus || "");
      var documentName = String(this.findValueByKeysDeep(primary, function (key, value) { return /document.*name|file.*name|name/i.test(String(key || "")) && typeof value === "string" && /\.pdf$/i.test(String(value || "").trim()); }) || "").trim();
      return { contractStatusCode: rawStatus == null ? "" : String(rawStatus), contractStatusText: statusText || "Đang chờ cập nhật", signStatusCode: rawSignStatus == null ? String(rawStatus == null ? "" : rawStatus) : String(rawSignStatus), signStatusText: statusText || "Đang chờ cập nhật", documentName: documentName, isCompleted: statusText === "Hoàn thành" };
    },
    isEcontractCompletedStatus: function (summary) {
      var contractStatus = Number(summary && summary.contractStatusCode || 0);
      var signStatus = Number(summary && summary.signStatusCode || 0);
      return contractStatus === 9 || contractStatus === 10 || signStatus === 8;
    },
    extractWeSignDownloadPayload: function (response, documentId) {
      var root = this.extractEcontractResponseObject(response) || response || {};
      var fileBase64 = this.normalizeBase64Content(this.findValueByKeysDeep(root, function (key, value) { return /base64|binary|content/i.test(String(key || "")) && typeof value === "string" && String(value || "").trim().length > 100; }) || "");
      var fileUrl = String(this.findValueByKeysDeep(root, function (key, value) { return /url|download/i.test(String(key || "")) && typeof value === "string" && /^https?:\/\//i.test(String(value || "").trim()); }) || "").trim();
      var fileName = String(this.findValueByKeysDeep(root, function (key, value) { return /file.?name|document.?name|name/i.test(String(key || "")) && typeof value === "string" && /\.pdf$/i.test(String(value || "").trim()); }) || "").trim();
      return { fileBase64: fileBase64, fileUrl: fileUrl, fileName: fileName || ("wesign-" + String(documentId || this.instanceId || "signed") + ".pdf"), fileContentType: "application/pdf" };
    },
    findValueByKeysDeep: function (input, matchFn) {
      var queue = [input];
      var node = null;
      var key = "";
      var value = null;
      var i = 0;
      while (queue.length > 0) {
        node = queue.shift();
        if (!node || typeof node !== "object") continue;
        if (Array.isArray(node)) {
          for (i = 0; i < node.length; i += 1) queue.push(node[i]);
          continue;
        }
        for (key in node) {
          if (!Object.prototype.hasOwnProperty.call(node, key)) continue;
          value = node[key];
          if (matchFn(key, value)) return value;
          if (value && typeof value === "object") queue.push(value);
        }
      }
      return null;
    },
    isProbablyPdfBase64: function (base64) {
      var normalized = this.normalizeBase64Content(base64);
      var head = String(normalized || "").slice(0, 40);
      if (!head) return false;
      if (head.indexOf("JVBERi0") === 0) return true;
      if (head.indexOf("PCFkb2N0eXBlIGh0bWw") === 0) return false;
      if (head.indexOf("PGh0bWw") === 0) return false;
      return false;
    },
    uploadEcontractDownloadedFile: async function (downloadPayload) {
      var uploadRes = null;
      var row = null;
      if (!downloadPayload || !downloadPayload.fileBase64) return null;
      if (!this.isProbablyPdfBase64(downloadPayload.fileBase64)) throw new Error("File signed từ provider hiện chưa phải PDF hợp lệ. Provider đang trả HTML/login shell thay vì PDF.");
      uploadRes = await apiCallAsync("UPLOAD_FileData_Base64", { FileBase64: downloadPayload.fileBase64, FileName: downloadPayload.fileName || ("econtract-" + this.instanceId + ".pdf"), FileContentType: downloadPayload.fileContentType || "application/pdf" });
      row = uploadRes && uploadRes[0] ? uploadRes[0] : null;
      if (!row && uploadRes && uploadRes.data && uploadRes.data[0]) row = uploadRes.data[0][0] || uploadRes.data[0];
      if (!row) return null;
      return { FileID: row.FileID || "", FileName: row.FileName || downloadPayload.fileName || ("econtract-" + this.instanceId + ".pdf") };
    },
    applyWeSignTrackingSummary: function (summary, downloadPayload, uploadedFile) {
      if (!summary) return;
      this.overview.ExternalContractStatusCode = summary.contractStatusCode || "";
      this.overview.ExternalContractStatusText = summary.contractStatusText || "";
      this.overview.ExternalSignStatusCode = summary.signStatusCode || "";
      this.overview.ExternalSignStatusText = summary.signStatusText || "";
      this.overview.ExternalLastSyncTime = new Date().toISOString();
      if (summary.documentName) this.overview.ExternalDocumentName = summary.documentName;
      if (downloadPayload && downloadPayload.fileUrl) this.overview.ExternalDocumentUrl = downloadPayload.fileUrl;
      if (downloadPayload && downloadPayload.fileName) this.overview.ExternalDocumentName = downloadPayload.fileName;
      if (uploadedFile && uploadedFile.FileID) {
        this.overview.CurrentDocumentFileID = uploadedFile.FileID;
        this.overview.CurrentDocumentFileUrl = "https://file.zentea.vn/iotdev/FileData/" + uploadedFile.FileID;
        this.overview.CurrentDocumentFileName = uploadedFile.FileName || this.overview.CurrentDocumentFileName;
      }
    },
    loadWeSignSignedDocument: async function (silent) {
      var documentId = this.resolveWeSignDocumentId();
      var response = null;
      var payload = null;
      var uploadedFile = null;
      if (!documentId) throw new Error("Thiếu documentId AMIS WeSign để tải file đã ký.");
      response = await this.econtractRequest("POST", this.resolveEcontractUrl(this.eContractApiMap.wesignDownloadSigned), { DocumentIds: [documentId] }, "");
      payload = this.extractWeSignDownloadPayload(response, documentId);
      if (!payload.fileBase64 && !payload.fileUrl) throw new Error("AMIS WeSign chưa trả về file đã ký hợp lệ.");
      if (payload.fileBase64 && this.isProbablyPdfBase64(payload.fileBase64)) {
        uploadedFile = await this.uploadEcontractDownloadedFile(payload);
        if (!silent) this.triggerBlobDownload(this.base64ToBlob(payload.fileBase64, payload.fileContentType), payload.fileName);
      } else if (payload.fileUrl && !silent && typeof window !== "undefined") {
        window.open(payload.fileUrl, "_blank");
      }
      this.applyWeSignTrackingSummary({ contractStatusCode: this.overview.ExternalContractStatusCode, contractStatusText: this.overview.ExternalContractStatusText, signStatusCode: this.overview.ExternalSignStatusCode, signStatusText: this.overview.ExternalSignStatusText, documentName: payload.fileName || this.overview.ExternalDocumentName }, payload, uploadedFile);
      return payload;
    },
    syncWeSignRuntime: async function (silent) {
      var documentId = this.resolveWeSignDocumentId();
      var response = null;
      var summary = null;
      var lhbsAuthorization = "";
      var syncedFileId = "";
      var syncedFileName = "";
      var externalDocumentUrl = "";
      if (!documentId) throw new Error("Thiếu documentId AMIS WeSign để kiểm tra trạng thái.");
      lhbsAuthorization = this.resolveLhbsAuthorization();
      if (!lhbsAuthorization) throw new Error("Không lấy được token LHBS để đồng bộ AMIS WeSign.");
      response = await this.econtractRequest("POST", this.resolveEcontractUrl(this.eContractApiMap.wesignSyncRuntime, documentId), {
        InstanceID: this.instanceId,
        LhbsAuthorization: lhbsAuthorization
      }, "");
      summary = {
        contractStatusCode: String(response && (response.contractStatusCode || response.ContractStatusCode || "") || "").trim(),
        contractStatusText: String(response && (response.contractStatusText || response.ContractStatusText || "") || "").trim(),
        signStatusCode: String(response && (response.signStatusCode || response.SignStatusCode || "") || "").trim(),
        signStatusText: String(response && (response.signStatusText || response.SignStatusText || "") || "").trim(),
        documentName: String(response && (response.downloadFileName || response.DownloadFileName || this.overview.ExternalDocumentName || "") || "").trim()
      };
      syncedFileId = String(response && (response.downloadFileId || response.DownloadFileId || "") || "").trim();
      syncedFileName = String(response && (response.downloadFileName || response.DownloadFileName || "") || "").trim();
      externalDocumentUrl = String(response && (response.externalDocumentUrl || response.ExternalDocumentUrl || "") || "").trim();
      this.applyWeSignTrackingSummary(summary, externalDocumentUrl ? { fileUrl: externalDocumentUrl, fileName: syncedFileName } : null, syncedFileId ? {
        FileID: syncedFileId,
        FileName: syncedFileName || this.overview.CurrentDocumentFileName || ("wesign-" + this.instanceId + ".pdf")
      } : null);
      await this.loadDetail();
      if (!silent && showToast && showToast.success) showToast.success("Đã cập nhật trạng thái ký từ " + this.currentExternalProviderText + ".");
    },
    syncEcontractRuntime: async function (silent) {
      var hopDongId = 0;
      var lhbsAuthorization = "";
      if (this.isEcontractSyncing || !this.shouldSyncEcontract()) return;
      this.isEcontractSyncing = true;
      try {
        if (this.resolveOverviewContractProvider() === "AMIS_WESIGN") {
          await this.syncWeSignRuntime(silent);
          return;
        }
        hopDongId = this.resolveEcontractHopDongId();
        if (hopDongId <= 0) return;
        lhbsAuthorization = this.resolveLhbsAuthorization();
        if (!lhbsAuthorization) throw new Error("Không lấy được token LHBS để đồng bộ eContract.");
        await this.econtractRequest("POST", this.resolveEcontractUrl(this.eContractApiMap.syncRuntime, hopDongId), { InstanceID: this.instanceId, HopDongID: hopDongId, LhbsAuthorization: lhbsAuthorization }, "");
        await this.loadDetail();
        if (!silent && showToast && showToast.success) showToast.success("Đã cập nhật trạng thái ký từ " + this.currentExternalProviderText + ".");
      } catch (err) {
        if (!silent) this.showError(err, "Kiểm tra trạng thái ký thất bại.");
      } finally {
        this.isEcontractSyncing = false;
      }
    }
  }
}
if (typeof window !== "undefined") {
  window.__WF_REQUEST_DETAIL_EXTERNAL_MIXIN__ = wfRequestDetailExternalMixin;
}
function loadWfRequestDetailImportSync(fileName) {
  var scriptUrl = "";
  var xhr = null;
  if (typeof window === "undefined" || typeof document === "undefined" || typeof XMLHttpRequest === "undefined") return false;
  if (window.__WF_REQUEST_DETAIL_IMPORT_CACHE__ && window.__WF_REQUEST_DETAIL_IMPORT_CACHE__[fileName]) return true;
  try {
    scriptUrl = "";
    if (document.currentScript && document.currentScript.src) scriptUrl = String(document.currentScript.src || "");
    if (!scriptUrl) return false;
    scriptUrl = scriptUrl.replace(/\/script\.js(\?.*)?$/i, "/imports/" + String(fileName || "").replace(/^\/+/, ""));
    if (!scriptUrl || /\/script\.js(\?.*)?$/i.test(scriptUrl)) return false;
    xhr = new XMLHttpRequest();
    xhr.open("GET", scriptUrl, false);
    xhr.send(null);
    if (!((xhr.status >= 200 && xhr.status < 300) || xhr.status === 0)) return false;
    window.__WF_REQUEST_DETAIL_IMPORT_CACHE__ = window.__WF_REQUEST_DETAIL_IMPORT_CACHE__ || {};
    (0, eval)(String(xhr.responseText || ""));
    window.__WF_REQUEST_DETAIL_IMPORT_CACHE__[fileName] = true;
    return true;
  } catch (e) {
    return false;
  }
}
if (typeof window !== "undefined" && !window.__WF_REQUEST_DETAIL_SMARTCA_MIXIN__ && !window.__WF_REQUEST_DETAIL_IMPORT_ATTEMPTED__) {
  window.__WF_REQUEST_DETAIL_IMPORT_ATTEMPTED__ = true;
  loadWfRequestDetailImportSync("wf-request-detail-smartca.js");
}
if (typeof window === "undefined" || !window.__WF_REQUEST_DETAIL_SMARTCA_MIXIN__) {
var wfRequestDetailSmartcaMixin = {
  methods: {
    getDefaultSmartcaSignatureImageBase64: function () {
      return "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wn2fQAAAABJRU5ErkJggg==";
    },
    formatSmartcaSignDateTime: function (value) {
      var dt = value ? new Date(value) : new Date();
      if (!dt || Number.isNaN(dt.getTime())) dt = new Date();
      var dd = String(dt.getDate()).padStart(2, "0");
      var mm = String(dt.getMonth() + 1).padStart(2, "0");
      var yyyy = String(dt.getFullYear());
      var hh = String(dt.getHours()).padStart(2, "0");
      var mi = String(dt.getMinutes()).padStart(2, "0");
      return dd + "/" + mm + "/" + yyyy + " " + hh + ":" + mi;
    },
    buildSmartcaVisualStampBase64: function (signerName, signTimeText) {
      var nameText = String(signerName || "").trim() || "NGƯỜI KÝ";
      var dateText = String(signTimeText || "").trim() || this.formatSmartcaSignDateTime();
      var canvas = null;
      var ctx = null;
      var dataUrl = "";
      var centerX = 0;
      var maxNameWidth = 0;
      var maxDateWidth = 0;
      var nameFontSize = 64;
      var dateFontSize = 38;
      try {
        if (typeof document === "undefined" || !document.createElement) return "";
        canvas = document.createElement("canvas");
        canvas.width = 900;
        canvas.height = 300;
        ctx = canvas.getContext("2d");
        if (!ctx) return "";
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = "rgba(255,255,255,0)";
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        centerX = Math.round(canvas.width / 2);
        maxNameWidth = canvas.width - 40;
        maxDateWidth = canvas.width - 60;
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillStyle = "#0f8a43";
        while (nameFontSize > 34) {
          ctx.font = "700 " + nameFontSize + "px 'Arial', sans-serif";
          if (ctx.measureText(nameText).width <= maxNameWidth) break;
          nameFontSize -= 2;
        }
        ctx.fillText(nameText, centerX, 105);
        ctx.fillStyle = "#1f4f99";
        while (dateFontSize > 24) {
          ctx.font = "500 " + dateFontSize + "px 'Arial', sans-serif";
          if (ctx.measureText("Ngày ký: " + dateText).width <= maxDateWidth) break;
          dateFontSize -= 1;
        }
        ctx.fillText("Ngày ký: " + dateText, centerX, 230);
        dataUrl = canvas.toDataURL("image/png");
        if (!dataUrl || dataUrl.indexOf("base64,") < 0) return "";
        return dataUrl.split("base64,").pop() || "";
      } catch (e) {
        return "";
      }
    },
    buildTextSignatureImageBase64: function (text) {
      var label = String(text || "").trim() || "SmartCA";
      var canvas = null;
      var ctx = null;
      var dataUrl = "";
      try {
        if (typeof document === "undefined" || !document.createElement) return "";
        canvas = document.createElement("canvas");
        canvas.width = 640;
        canvas.height = 180;
        ctx = canvas.getContext("2d");
        if (!ctx) return "";
        ctx.fillStyle = "#ffffff";
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = "#0b5cab";
        ctx.font = "italic 700 48px 'Times New Roman', serif";
        ctx.textBaseline = "middle";
        ctx.fillText(label, 24, 90);
        dataUrl = canvas.toDataURL("image/png");
        if (!dataUrl || dataUrl.indexOf("base64,") < 0) return "";
        return dataUrl.split("base64,").pop() || "";
      } catch (e) {
        return "";
      }
    },
    getSmartcaUploadedSignatureImageBase64: async function () {
      var signatureFileId = "";
      var rows = [];
      var row = null;
      var base64 = "";
      if (this.smartcaUploadedSignatureBase64) return this.smartcaUploadedSignatureBase64;
      base64 = this.normalizeBase64Content(this.mySignerProfile && this.mySignerProfile.ImgSign);
      if (base64) {
        this.smartcaUploadedSignatureBase64 = base64;
        return base64;
      }
      signatureFileId = this.mySignerProfile && this.mySignerProfile.SignatureFileID ? String(this.mySignerProfile.SignatureFileID).trim() : "";
      if (!signatureFileId) return "";
      try {
        rows = await apiCallAsync("FileData_GetByID", { FileID: signatureFileId });
        row = rows && rows[0] ? rows[0] : null;
        base64 = this.normalizeBase64Content(row && (row.BinaryContent || row.FILE_CONTENT || row.File_Binary || ""));
        if (base64) {
          this.smartcaUploadedSignatureBase64 = base64;
          return base64;
        }
      } catch (e) {
      }
      base64 = await this.fetchFileBase64FromPublicUrl(signatureFileId);
      if (base64) {
        this.smartcaUploadedSignatureBase64 = base64;
        return base64;
      }
      return "";
    },
    getSmartcaSignatureImageBase64: async function () {
      var uploadedBase64 = await this.getSmartcaUploadedSignatureImageBase64();
      var textSign = String(this.mySignerProfile && this.mySignerProfile.TextSign || this.mySignerProfile && this.mySignerProfile.FullName || this.overview.CurrentSignerPersonName || "").trim();
      if (uploadedBase64) {
        this.smartcaSignatureBase64 = uploadedBase64;
        return uploadedBase64;
      }
      this.smartcaSignatureBase64 = this.buildTextSignatureImageBase64(textSign) || this.getDefaultSmartcaSignatureImageBase64();
      return this.smartcaSignatureBase64;
    },
    resolveCurrentSignerRow: function () {
      var currentExecId = Number(this.overview.CurrentSignerExecID || 0);
      var rows = this.signers || [];
      var i = 0;
      for (i = 0; i < rows.length; i += 1) {
        if (Number(rows[i].SignerExecID || 0) === currentExecId) return rows[i];
      }
      return null;
    },
    resolveCurrentSignBox: function () {
      var signer = this.resolveCurrentSignerRow();
      var currentSignerExecId = Number(this.overview.CurrentSignerExecID || 0);
      var stepOrder = Number(this.overview.CurrentStepOrder || 0);
      var signerOrder = signer ? Number(signer.SignerOrder || 0) : 0;
      var rows = this.signBoxes || [];
      var i = 0;
      var row = null;
      if (currentSignerExecId > 0) {
        for (i = 0; i < rows.length; i += 1) {
          row = rows[i];
          if (Number(row.SignerExecID || 0) === currentSignerExecId) return row;
        }
        // Không tìm thấy theo SignerExecID (sign box có thể thuộc execution cũ) → fallback theo StepOrder + SignerOrder
      }
      for (i = 0; i < rows.length; i += 1) {
        row = rows[i];
        if (Number(row.StepOrder || 0) === stepOrder && Number(row.SignerOrder || 0) === signerOrder) return row;
      }
      for (i = 0; i < rows.length; i += 1) {
        row = rows[i];
        if (Number(row.StepOrder || 0) === stepOrder) return row;
      }
      return rows[0] || null;
    },
    resolveSmartcaSignerUserId: function () {
      var employeeCode = this.mySignerProfile && this.mySignerProfile.EmployeeCode ? String(this.mySignerProfile.EmployeeCode).trim() : "";
      if (employeeCode) return employeeCode;
      var current = this.overview && this.overview.CurrentSignerPersonID != null ? String(this.overview.CurrentSignerPersonID).trim() : "";
      if (current) return current;
      var legacy = this.mySignerProfile && this.mySignerProfile.LegacyUserID != null ? String(this.mySignerProfile.LegacyUserID).trim() : "";
      if (legacy) return legacy;
      var email = this.mySignerProfile && this.mySignerProfile.Email ? String(this.mySignerProfile.Email).trim() : "";
      if (email) return email;
      return "";
    },
    resolveSmartcaAccessToken: function () {
      try {
        if (typeof $awt !== "undefined" && $awt) return String($awt);
      } catch (e) {
      }
      return "";
    },
    resolveLhbsAuthorization: function () {
      return this.resolveSmartcaAccessToken();
    },
    resolveSmartcaEndpoint: function () {
      var override = "";
      try {
        if (typeof window !== "undefined" && window && window.__WF_SMARTCA_ENDPOINT__) {
          override = String(window.__WF_SMARTCA_ENDPOINT__).trim();
        }
      } catch (e) {
      }
      if (!override) {
        try {
          if (typeof localStorage !== "undefined" && localStorage) {
            override = String(localStorage.getItem("WF_SMARTCA_ENDPOINT") || "").trim();
          }
        } catch (e2) {
        }
      }
      if (override) return override;
      return "https://ca-uat.iotsoftvn.com/api/sync-async/dev-v3";
    },
    resolveSmartcaApiKey: function () {
      var override = "";
      try {
        if (typeof window !== "undefined" && window && window.__WF_SMARTCA_APIKEY__) {
          override = String(window.__WF_SMARTCA_APIKEY__).trim();
        }
      } catch (e) {
      }
      if (!override) {
        try {
          if (typeof localStorage !== "undefined" && localStorage) {
            override = String(localStorage.getItem("WF_SMARTCA_APIKEY") || "").trim();
          }
        } catch (e2) {
        }
      }
      if (override) return override;
      return "eGFjLXRodWMtdHUtbGh1LWVkdS12bkAyMDI1QGZ1aS52bg==";
    },
    // fetchRuntimeFileData: async function () {
    //   var runtime = this.resolveBestRuntimeDocument();
    //   var targetFileId = runtime.FileID || null;
    //   var rows = [];
    //   var row = null;
    //   if (!targetFileId) return null;
    //   rows = await apiCallAsync("FileData_GetByID", { FileID: targetFileId });
    //   row = rows && rows[0] ? rows[0] : null;
    //   if (!row) return null;
    //   return {
    //     FileID: row.FileID || targetFileId,
    //     FileName: row.FileName || runtime.FileName || ("WF-" + this.instanceId + ".pdf"),
    //     BinaryBase64: this.normalizeBase64Content(row.BinaryContent || row.FILE_CONTENT || row.File_Binary || "")
    //   };
    // },
    fetchRuntimeFileData: async function () {
      if (this.lastMergedPdfBase64) {
        return {
          FileID: "merged-" + this.instanceId,
          FileName: "WF-" + this.instanceId + ".pdf",
          BinaryBase64: this.lastMergedPdfBase64
        };
      }
      var runtime = this.resolveBestRuntimeDocument();
      var targetFileId = runtime.FileID || null;
      var match = null;
      var rows = [];
      var row = null;
      var base64 = "";
      if (!targetFileId && runtime.FileUrl) {
        match = String(runtime.FileUrl).match(/\/FileData\/([A-Za-z0-9_-]+)/i);
        if (match && match[1]) targetFileId = match[1];
      }
      if (!targetFileId) return null;
      if (typeof this.fetchFileBase64FromPublicUrl === "function") {
        try {
          base64 = await this.fetchFileBase64FromPublicUrl(targetFileId);
        } catch (e) {}
      }
      if (base64) {
        return {
          FileID: targetFileId,
          FileName: runtime.FileName || ("WF-" + this.instanceId + ".pdf"),
          BinaryBase64: this.normalizeBase64Content(base64)
        };
      }
      rows = await apiCallAsync("FileData_GetByID", { FileID: targetFileId });
      row = rows && rows[0] ? rows[0] : null;
      if (!row) return null;
      return {
        FileID: row.FileID || targetFileId,
        FileName: row.FileName || runtime.FileName || ("WF-" + this.instanceId + ".pdf"),
        BinaryBase64: this.normalizeBase64Content(row.BinaryContent || row.FILE_CONTENT || row.File_Binary || row.FileData || "")
      };
    },
    callSmartCAInternalSign: async function () {
      var endpoint = this.resolveSmartcaEndpoint();
      var apiKey = this.resolveSmartcaApiKey();
      var signBox = this.resolveCurrentSignBox();
      var fileData = await this.fetchRuntimeFileData();
      var approvedCert = this.approvedSignerCertInfo ? String(this.approvedSignerCertInfo).trim() : "";
      var profileCert = this.mySignerProfile && this.mySignerProfile.CertSerial ? String(this.mySignerProfile.CertSerial).trim() : "";
      var certSerial = approvedCert || profileCert;
      var signerUserId = this.resolveSmartcaSignerUserId();
      var accessToken = this.resolveSmartcaAccessToken();
      var signDateTimeText = this.formatSmartcaSignDateTime();
      var resolvedTextSign = String(this.mySignerProfile && this.mySignerProfile.TextSign || this.mySignerProfile && this.mySignerProfile.FullName || this.overview.CurrentSignerPersonName || "SmartCA Signer").trim();
      var optionSign = this.resolveSmartcaOptionSign();
      var uploadedSignatureBase64 = "";
      var imgSignBase64 = "";
      var hasRealSignatureImage = false;
      var payload = {};
      var payloadJson = "";
      var response = null;
      var debugInfo = null;
      if (!fileData || !fileData.BinaryBase64) throw new Error("Không lấy được file runtime để gửi SmartCA.");
      if (!certSerial) throw new Error("Không có chứng thư số active trong hồ sơ người ký.");
      if (!signBox) throw new Error("Không xác định được vị trí ký runtime để gọi SmartCA.");
      if (!signerUserId) throw new Error("Thiếu NguoiKyID để gọi SmartCA (chưa map user ký).");
      if (optionSign === "1") {
        uploadedSignatureBase64 = await this.getSmartcaUploadedSignatureImageBase64();
        hasRealSignatureImage = !!uploadedSignatureBase64;
        imgSignBase64 = uploadedSignatureBase64 || this.buildSmartcaVisualStampBase64(resolvedTextSign || "NGƯỜI KÝ", signDateTimeText) || await this.getSmartcaSignatureImageBase64();
      } else {
        imgSignBase64 = this.buildSmartcaVisualStampBase64(resolvedTextSign || "NGƯỜI KÝ", signDateTimeText) || await this.getSmartcaSignatureImageBase64();
      }
      if (!imgSignBase64) throw new Error("Thiếu ảnh chữ ký (ImgSign) để gọi SmartCA.");
      payload = {
        DocName: fileData.FileName || ("WF-" + this.instanceId + ".pdf"),
        DocFile: fileData.BinaryBase64,
        MoTaGiaoDich: this.overview.InstanceName || ("WF Instance " + this.instanceId),
        UserIDSign: certSerial,
        LocationSign: await this.buildSmartcaLocationSign(signBox),
        PageNumber: this.toSafeInt(signBox.PageNo || 1, 1),
        TextSign: resolvedTextSign || "SmartCA Signer",
        ImgSign: imgSignBase64 || "",
        PDF_ID: this.toSafeInt(this.instanceId, 0),
        ChiTietID: this.toSafeInt(this.overview.CurrentSignerExecID || 0, 0),
        NguoiKyID: String(signerUserId || ""),
        OptionSign: optionSign,
        FontName: "Times New Roman",
        FontColor: "#000000",
        FontSize: 12,
        AccessCode: "",
        AccessToken: accessToken
      };
      payload.OptionSign = String(payload.OptionSign == null ? "1" : payload.OptionSign);
      Object.keys(payload).forEach(function (key) {
        if (payload[key] === null || typeof payload[key] === "undefined") payload[key] = "";
      });
      if (!String(payload.DocFile || "").trim()) throw new Error("DocFile rỗng, không gọi SmartCA.");
      if (!String(payload.UserIDSign || "").trim()) throw new Error("UserIDSign rỗng, không gọi SmartCA.");
      if (!String(payload.NguoiKyID || "").trim()) throw new Error("NguoiKyID rỗng, không gọi SmartCA.");
      if (!String(payload.LocationSign || "").trim()) throw new Error("LocationSign rỗng, không gọi SmartCA.");
      if (!String(payload.ImgSign || "").trim()) throw new Error("ImgSign rỗng, không gọi SmartCA.");
      payloadJson = JSON.stringify(payload);
      if (payloadJson.indexOf("\"OptionSign\":\"") < 0) throw new Error("Payload SmartCA không hợp lệ: OptionSign chưa ở dạng chuỗi.");
      debugInfo = {
        endpoint: endpoint,
        hasRealSignatureImage: hasRealSignatureImage,
        optionSign: payload.OptionSign,
        textSign: payload.TextSign,
        textSignLen: String(payload.TextSign || "").length,
        fontName: payload.FontName,
        fontColor: payload.FontColor,
        fontSize: payload.FontSize,
        signDateTimeText: signDateTimeText,
        pageNumber: payload.PageNumber,
        pdfId: payload.PDF_ID,
        chiTietId: payload.ChiTietID,
        locationSign: payload.LocationSign,
        userIdSign: payload.UserIDSign,
        nguoiKyId: payload.NguoiKyID,
        docName: payload.DocName,
        docFileLen: String(payload.DocFile || "").length,
        imgSignLen: String(payload.ImgSign || "").length,
        payloadJsonLen: payloadJson.length,
        docFileHead: String(payload.DocFile || "").slice(0, 24),
        imgSignHead: String(payload.ImgSign || "").slice(0, 24),
        accessTokenLen: String(payload.AccessToken || "").length
      };
      if (typeof console !== "undefined" && console && console.log) console.log("[WF][SmartCA][RequestDebug]", debugInfo);
      if (typeof window !== "undefined") window.__WF_SMARTCA_LAST_DEBUG__ = debugInfo;
      this.isSmartcaCalling = true;
      try {
        try {
          response = await $.ajax({
            type: "POST",
            headers: { "X-API-KEY": apiKey },
            url: endpoint,
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            crossDomain: true,
            data: payloadJson
          });
        } catch (ajaxErr) {
          if (typeof console !== "undefined" && console && console.error) {
            console.error("[WF][SmartCA][ResponseError]", {
              status: ajaxErr && ajaxErr.status,
              statusText: ajaxErr && ajaxErr.statusText,
              responseText: ajaxErr && ajaxErr.responseText,
              responseJSON: ajaxErr && ajaxErr.responseJSON
            });
          }
          throw ajaxErr;
        }
      } finally {
        this.isSmartcaCalling = false;
      }
      if (!response) throw new Error("SmartCA không trả về dữ liệu.");
      if (response.IsSuccess === false) throw new Error(response.Message || "SmartCA từ chối giao dịch ký.");
      // Debug: log tất cả keys của response để xác định field FileID
      if (typeof console !== "undefined" && console && console.log) {
        var responseKeys = Object.keys(response || {}).map(function(k) {
          var v = response[k];
          return k + ": " + (typeof v === "string" ? "[string len=" + v.length + "]" : (typeof v));
        });
        console.log("[WF][SmartCA][ResponseKeys]", responseKeys);
        console.log("[WF][SmartCA][ResponseRaw]", JSON.stringify(response).slice(0, 500));
      }
      return response;
    }
  }
}
if (typeof window !== "undefined") {
  window.__WF_REQUEST_DETAIL_SMARTCA_MIXIN__ = wfRequestDetailSmartcaMixin;
}
}
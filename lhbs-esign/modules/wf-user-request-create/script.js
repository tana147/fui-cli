function loadWfRequestCreateImportSync(fileName) {
  var scriptUrl = "";
  var xhr = null;
  if (typeof window === "undefined" || typeof document === "undefined" || typeof XMLHttpRequest === "undefined") return false;
  if (window.__WF_REQUEST_CREATE_IMPORT_CACHE__ && window.__WF_REQUEST_CREATE_IMPORT_CACHE__[fileName]) return true;
  try {
    if (document.currentScript && document.currentScript.src) scriptUrl = String(document.currentScript.src || "");
    if (!scriptUrl) return false;
    scriptUrl = scriptUrl.replace(/\/script\.js(\?.*)?$/i, "/imports/" + String(fileName || "").replace(/^\/+/, ""));
    if (!scriptUrl || /\/script\.js(\?.*)?$/i.test(scriptUrl)) return false;
    xhr = new XMLHttpRequest();
    xhr.open("GET", scriptUrl, false);
    xhr.send(null);
    if (!((xhr.status >= 200 && xhr.status < 300) || xhr.status === 0)) return false;
    window.__WF_REQUEST_CREATE_IMPORT_CACHE__ = window.__WF_REQUEST_CREATE_IMPORT_CACHE__ || {};
    (0, eval)(String(xhr.responseText || ""));
    window.__WF_REQUEST_CREATE_IMPORT_CACHE__[fileName] = true;
    return true;
  } catch (e) {
    return false;
  }
}
if (typeof window !== "undefined" && !window.__WF_REQUEST_CREATE_ECONTRACT_MIXIN__ && !window.__WF_REQUEST_CREATE_IMPORT_ATTEMPTED__) {
  window.__WF_REQUEST_CREATE_IMPORT_ATTEMPTED__ = true;
  loadWfRequestCreateImportSync("wf-request-create-econtract.js");
}
if (typeof window === "undefined" || !window.__WF_REQUEST_CREATE_ECONTRACT_MIXIN__) {
  var wfRequestCreateEcontractMixin = {
    methods: {
      resolveEcontractProxyBase: function () {
        var base = "";
        try {
          if (typeof window !== "undefined" && window && window.__WF_ECONTRACT_PROXY_BASE__) {
            base = String(window.__WF_ECONTRACT_PROXY_BASE__ || "").trim();
          }
        } catch (e) {
        }
        if (!base) {
          try {
            if (typeof localStorage !== "undefined" && localStorage) {
              base = String(localStorage.getItem("WF_ECONTRACT_PROXY_BASE") || "").trim();
            }
          } catch (e2) {
          }
        }
        if (!base) base = "https://ca-uat.iotsoftvn.com";
        return base.replace(/\/+$/, "");
      },
      buildEcontractUrl: function (path) {
        var cleanPath = String(path || "").trim();
        var base = this.resolveEcontractProxyBase();
        if (!cleanPath) return base;
        if (!base) return cleanPath;
        if (cleanPath.indexOf("http://") === 0 || cleanPath.indexOf("https://") === 0) return cleanPath;
        if (cleanPath.charAt(0) !== "/") cleanPath = "/" + cleanPath;
        return base + cleanPath;
      },
      buildEcontractApiPath: function (path, replacements) {
        var resolvedPath = String(path || "").trim();
        var key = "";
        if (!resolvedPath) return resolvedPath;
        replacements = replacements && typeof replacements === "object" ? replacements : {};
        for (key in replacements) {
          if (!Object.prototype.hasOwnProperty.call(replacements, key)) continue;
          resolvedPath = resolvedPath.replace(new RegExp("\\{" + key + "\\}", "g"), String(replacements[key]));
        }
        return resolvedPath;
      },
      resolveEcontractApiKey: function () {
        var key = "";
        try {
          if (typeof window !== "undefined" && window && window.__WF_ECONTRACT_APIKEY__) {
            key = String(window.__WF_ECONTRACT_APIKEY__ || "").trim();
          }
        } catch (e) {
        }
        if (!key) {
          try {
            if (typeof localStorage !== "undefined" && localStorage) {
              key = String(localStorage.getItem("WF_ECONTRACT_APIKEY") || "").trim();
            }
          } catch (e2) {
          }
        }
        if (!key) key = "eGFjLXRodWMtdHUtbGh1LWVkdS12bkAyMDI1QGZ1aS52bg==";
        return key;
      },
      econtractRequest: async function (method, path, payload, authToken) {
        var url = this.buildEcontractUrl(path);
        var apiKey = this.resolveEcontractApiKey();
        var headers = { "X-API-KEY": apiKey };
        var requestData = payload == null ? {} : payload;
        var requestConfig = {
          type: method || "POST",
          url: url,
          headers: headers,
          dataType: "json",
          crossDomain: true
        };
        if (authToken) headers.Authorization = String(authToken).indexOf("Bearer ") === 0 ? String(authToken) : "Bearer " + String(authToken);
        if (String(method || "POST").toUpperCase() !== "GET") {
          requestConfig.contentType = "application/json; charset=utf-8";
          requestConfig.data = JSON.stringify(requestData);
        }
        return await $.ajax(requestConfig);
      },
      extractTokenFromLoginResponse: function (response) {
        var queue = [];
        var node = null;
        var key = "";
        var token = "";
        if (!response) return "";
        queue.push(response);
        while (queue.length > 0) {
          node = queue.shift();
          if (!node || typeof node !== "object") continue;
          for (key in node) {
            if (!Object.prototype.hasOwnProperty.call(node, key)) continue;
            if (node[key] && typeof node[key] === "object") queue.push(node[key]);
            if (typeof node[key] === "string" && /token/i.test(key) && String(node[key]).trim()) {
              token = String(node[key]).trim();
              if (token.indexOf("Bearer ") === 0) return token;
              return "Bearer " + token;
            }
          }
        }
        return "";
      },
      extractHopDongId: function (response) {
        var queue = [];
        var node = null;
        var key = "";
        var value = null;
        var id = 0;
        if (!response) return 0;
        queue.push(response);
        while (queue.length > 0) {
          node = queue.shift();
          if (!node || typeof node !== "object") continue;
          for (key in node) {
            if (!Object.prototype.hasOwnProperty.call(node, key)) continue;
            value = node[key];
            if (value && typeof value === "object") queue.push(value);
            if (/hop[_-]?dong[_-]?id/i.test(key) || /^id$/i.test(key) || /^contractid$/i.test(key)) {
              id = Number(value || 0);
              if (id > 0) return id;
            }
          }
        }
        return 0;
      },
      extractFirstUuidByKeys: function (response, matcher) {
        var queue = [];
        var node = null;
        var key = "";
        var value = null;
        var raw = "";
        if (!response) return "";
        queue.push(response);
        while (queue.length > 0) {
          node = queue.shift();
          if (!node || typeof node !== "object") continue;
          if (Array.isArray(node)) {
            for (var i = 0; i < node.length; i += 1) queue.push(node[i]);
            continue;
          }
          for (key in node) {
            if (!Object.prototype.hasOwnProperty.call(node, key)) continue;
            value = node[key];
            if (value && typeof value === "object") queue.push(value);
            if (typeof value !== "string") continue;
            raw = String(value || "").trim();
            if (!raw) continue;
            if (matcher && !matcher(key, raw)) continue;
            if (/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(raw)) {
              return raw;
            }
          }
        }
        return "";
      },
      loginEcontract: async function () {
        var now = Date.now();
        var response = null;
        var token = "";
        if (this.econtractAuthCache && this.econtractAuthCache.token && Number(this.econtractAuthCache.expiredAt || 0) > now) {
          return this.econtractAuthCache.token;
        }
        response = await this.econtractRequest("POST", this.eContractApiMap.authLogin, {}, "");
        token = this.extractTokenFromLoginResponse(response);
        if (!token) throw new Error("Đăng nhập eContract thành công nhưng không lấy được access token.");
        this.econtractAuthCache = { token: token, expiredAt: Date.now() + (50 * 60 * 1000) };
        return token;
      },
      buildEcontractTemplatePayload: function (payload) {
        var i = 0;
        var vars = {};
        var signerRows = payload.Signers || [];
        var signerNames = [];
        for (i = 0; i < (payload.FieldValues || []).length; i += 1) {
          vars[payload.FieldValues[i].FieldName] = payload.FieldValues[i].Value == null ? "" : String(payload.FieldValues[i].Value);
        }
        for (i = 0; i < signerRows.length; i += 1) signerNames.push(signerRows[i].PersonName || signerRows[i].SignerValue || "");
        return {
          HopDong: {
            tieuDe: payload.InstanceName || "",
            maThamChieu: payload.ReferenceCode || "",
            moTa: payload.Description || "",
            templateId: payload.TemplateID || 0,
            executionEngine: payload.ExecutionEngine || "ECONTRACT",
            contractProvider: payload.ContractProvider || "VNPT_ECONTRACT",
            nguoiKy: signerNames
          },
          DanhSachBien: vars
        };
      },
      buildEcontractFilePayload: async function (payload) {
        var fileBase64 = String(this.form.fileBinaryBase64 || "").trim();
        var amountValue = 0;
        if (!fileBase64 && this.form.fileId) {
          await this.ensureDraftFileBinaryLoaded();
          fileBase64 = String(this.form.fileBinaryBase64 || "").trim();
        }
        if (!fileBase64 && this.form.fileId) fileBase64 = String(await this.tryReadFileBinaryById(this.form.fileId) || "").trim();
        if (!fileBase64) throw new Error("Không đọc được nội dung file để tạo hợp đồng eContract.");
        amountValue = this.resolveEcontractContractValue(payload);
        return {
          Data: {
            tenHopDong: payload.InstanceName || payload.ReferenceCode || "Hợp đồng điện tử",
            loaiTaiLieuId: this.resolveEcontractLoaiTaiLieuId(),
            hieuLucTu: null,
            hieuLucDen: null,
            loaiChungThucId: this.resolveEcontractLoaiChungThucId(),
            giaTriHD: amountValue,
            luongHDId: this.resolveEcontractLuongHdId(),
            ghiChu: payload.Description || "",
            kieuHopDongId: this.resolveEcontractKieuHopDongId(),
            soHopDong: payload.ReferenceCode || ""
          },
          FileBase64: fileBase64,
          FileName: this.form.uploadedFileName || payload.UploadFileName || "contract.pdf",
          FileContentType: this.form.uploadedFileMime || "application/pdf"
        };
      },
      resolveSubmitFileBase64: async function () {
        var fileBase64 = String(this.form.fileBinaryBase64 || "").trim();
        if (!fileBase64 && this.form.fileId) {
          await this.ensureDraftFileBinaryLoaded();
          fileBase64 = String(this.form.fileBinaryBase64 || "").trim();
        }
        if (!fileBase64 && this.form.fileId) {
          fileBase64 = String(await this.tryReadFileBinaryById(this.form.fileId) || "").trim();
        }
        return fileBase64;
      },
      buildWeSignCreateFlowPayload: async function (payload) {
        var fileBase64 = await this.resolveSubmitFileBase64();
        var signers = [];
        var signBoxes = [];
        var i = 0;
        var signer = null;
        var profile = null;
        var email = "";
        var phone = "";
        var signerOrder = 0;
        var boxSignerOrder = 0;
        if (!fileBase64) throw new Error("Không đọc được nội dung file để gửi AMIS WeSign.");
        if (!payload.Signers || payload.Signers.length <= 0) throw new Error("AMIS WeSign cần tối thiểu một người ký.");
        if (!payload.SignBoxes || payload.SignBoxes.length <= 0) throw new Error("AMIS WeSign cần tối thiểu một box ký.");
        for (i = 0; i < (payload.Signers || []).length; i += 1) {
          signer = payload.Signers[i] || {};
          profile = this.resolveSignerProfileBySignerValue(signer.SignerValue) || this.resolveSignerProfileByPersonName(signer.PersonName);
          email = String(profile && profile.Email || "").trim();
          phone = String(profile && (profile.Phone || profile.Mobile) || "").trim();
          signerOrder = Number(signer.SignOrder || signer.SignerOrder || (i + 1)) || (i + 1);
          if (!email) throw new Error("Người ký '" + String(signer.PersonName || signer.SignerValue || ("#" + (i + 1))) + "' chưa có email để gửi AMIS WeSign.");
          signers.push({
            SignerOrder: signerOrder,
            SignOrder: signerOrder,
            SignerValue: email,
            PersonName: signer.PersonName || "",
            Email: email,
            PhoneNumber: phone,
            Mobile: phone
          });
        }
        for (i = 0; i < (payload.SignBoxes || []).length; i += 1) {
          boxSignerOrder = Number(payload.SignBoxes[i].SignerOrder || 0) || 0;
          if (boxSignerOrder <= 0) throw new Error("Có box ký chưa gắn SignerOrder hợp lệ để gửi AMIS WeSign.");
          signBoxes.push({
            BoxOrder: Number(payload.SignBoxes[i].BoxOrder || (i + 1)) || (i + 1),
            SignerOrder: boxSignerOrder,
            Page: Number(payload.SignBoxes[i].PageNo || payload.SignBoxes[i].Page || 1) || 1,
            PageNo: Number(payload.SignBoxes[i].PageNo || payload.SignBoxes[i].Page || 1) || 1,
            X: Number(payload.SignBoxes[i].PosX != null ? payload.SignBoxes[i].PosX : payload.SignBoxes[i].X || 0) || 0,
            PosX: Number(payload.SignBoxes[i].PosX != null ? payload.SignBoxes[i].PosX : payload.SignBoxes[i].X || 0) || 0,
            Y: Number(payload.SignBoxes[i].PosY != null ? payload.SignBoxes[i].PosY : payload.SignBoxes[i].Y || 0) || 0,
            PosY: Number(payload.SignBoxes[i].PosY != null ? payload.SignBoxes[i].PosY : payload.SignBoxes[i].Y || 0) || 0,
            Width: Number(payload.SignBoxes[i].BoxWidth != null ? payload.SignBoxes[i].BoxWidth : payload.SignBoxes[i].Width || 0) || 0,
            BoxWidth: Number(payload.SignBoxes[i].BoxWidth != null ? payload.SignBoxes[i].BoxWidth : payload.SignBoxes[i].Width || 0) || 0,
            Height: Number(payload.SignBoxes[i].BoxHeight != null ? payload.SignBoxes[i].BoxHeight : payload.SignBoxes[i].Height || 0) || 0,
            BoxHeight: Number(payload.SignBoxes[i].BoxHeight != null ? payload.SignBoxes[i].BoxHeight : payload.SignBoxes[i].Height || 0) || 0
          });
        }
        return {
          FileBase64: fileBase64,
          FileName: this.form.uploadedFileName || payload.UploadFileName || "contract.pdf",
          DocumentName: payload.InstanceName || payload.ReferenceCode || "Hợp đồng điện tử",
          Description: payload.Description || "",
          IsOrderSign: payload.Sequential !== false,
          Signers: signers,
          SignBoxes: signBoxes
        };
      },
      validateWeSignPayload: async function (payload) {
        var signerOrders = [];
        var mappedOrders = {};
        var request = null;
        var i = 0;
        var order = 0;
        request = await this.buildWeSignCreateFlowPayload(payload);
        if (!request.FileBase64) throw new Error("AMIS WeSign yêu cầu file PDF trước khi gửi.");
        for (i = 0; i < (request.Signers || []).length; i += 1) {
          order = Number(request.Signers[i].SignerOrder || request.Signers[i].SignOrder || 0) || 0;
          if (order <= 0) throw new Error("Danh sách người ký AMIS WeSign có dòng thiếu SignerOrder.");
          if (!String(request.Signers[i].SignerValue || "").trim()) throw new Error("Danh sách người ký AMIS WeSign có dòng thiếu email.");
          if (signerOrders.indexOf(order) >= 0) throw new Error("SignerOrder của AMIS WeSign không được trùng.");
          signerOrders.push(order);
        }
        signerOrders.sort(function (a, b) { return a - b; });
        if (request.IsOrderSign) {
          for (i = 0; i < signerOrders.length; i += 1) {
            if (signerOrders[i] !== (i + 1)) throw new Error("SignerOrder của AMIS WeSign phải liên tục 1, 2, 3... khi ký tuần tự.");
          }
        }
        for (i = 0; i < (request.SignBoxes || []).length; i += 1) {
          order = Number(request.SignBoxes[i].SignerOrder || 0) || 0;
          if (order <= 0) throw new Error("Có box ký chưa map SignerOrder.");
          if (signerOrders.indexOf(order) < 0) throw new Error("Có box ký đang map tới SignerOrder không tồn tại.");
          mappedOrders[order] = true;
        }
        for (i = 0; i < signerOrders.length; i += 1) {
          if (!mappedOrders[signerOrders[i]]) throw new Error("Có người ký AMIS WeSign chưa được map box ký.");
        }
        return request;
      },
      extractEcontractDetailIds: function (response) {
        var queue = [];
        var node = null;
        var i = 0;
        var key = "";
        var value = null;
        var ids = [];
        var pushId = function (raw) {
          var parsed = Number(raw || 0);
          if (parsed > 0 && ids.indexOf(parsed) < 0) ids.push(parsed);
        };
        if (!response) return ids;
        queue.push(response);
        while (queue.length > 0) {
          node = queue.shift();
          if (!node) continue;
          if (Array.isArray(node)) {
            for (i = 0; i < node.length; i += 1) queue.push(node[i]);
            continue;
          }
          if (typeof node !== "object") continue;
          for (key in node) {
            if (!Object.prototype.hasOwnProperty.call(node, key)) continue;
            value = node[key];
            if (/hd[_-]?chi[_-]?tiet[_-]?id/i.test(key)) pushId(value);
            if (value && typeof value === "object") queue.push(value);
          }
        }
        return ids;
      },
      fetchEcontractDetailIds: async function (hopDongId, authToken) {
        var path = "";
        var response = null;
        var ids = [];
        if (Number(hopDongId || 0) <= 0) return ids;
        path = this.buildEcontractApiPath(this.eContractApiMap.detail, { hopDongId: Number(hopDongId || 0) });
        response = await this.econtractRequest("GET", path, null, authToken);
        ids = this.extractEcontractDetailIds(response);
        return ids;
      },
      resolveEcontractConfigValue: function (key, fallback) {
        var override = "";
        try {
          if (typeof window !== "undefined" && window && window.__WF_ECONTRACT_CONFIG__ && window.__WF_ECONTRACT_CONFIG__[key] != null) {
            override = String(window.__WF_ECONTRACT_CONFIG__[key]).trim();
          }
        } catch (e) {
        }
        if (!override) {
          try {
            if (typeof localStorage !== "undefined" && localStorage) {
              override = String(localStorage.getItem("WF_ECONTRACT_" + key.toUpperCase()) || "").trim();
            }
          } catch (e2) {
          }
        }
        if (override) return override;
        return fallback;
      },
      resolveEcontractLoaiTaiLieuId: function () {
        return Number(this.resolveEcontractConfigValue("loai_tai_lieu_id", "33")) || 33;
      },
      resolveEcontractLoaiChungThucId: function () {
        return Number(this.resolveEcontractConfigValue("loai_chung_thuc_id", "1")) || 1;
      },
      resolveEcontractKieuHopDongId: function () {
        return Number(this.resolveEcontractConfigValue("kieu_hop_dong_id", "1")) || 1;
      },
      resolveEcontractLuongHdId: function () {
        var raw = String(this.resolveEcontractConfigValue("luong_hd_id", "") || "").trim();
        if (!raw) return null;
        return Number(raw || 0) || null;
      },
      resolveEcontractContractValue: function (payload) {
        var rows = payload && payload.FieldValues ? payload.FieldValues : [];
        var i = 0;
        var fieldName = "";
        var rawValue = "";
        var normalized = "";
        for (i = 0; i < rows.length; i += 1) {
          fieldName = String(rows[i].FieldName || "").trim().toLowerCase();
          rawValue = rows[i].Value == null ? "" : String(rows[i].Value);
          if (fieldName.indexOf("gia_tri") >= 0 || fieldName.indexOf("amount") >= 0 || fieldName.indexOf("so_tien") >= 0) {
            normalized = rawValue.replace(/[^0-9.-]/g, "");
            if (normalized && !Number.isNaN(Number(normalized))) return Number(normalized);
          }
        }
        return 0;
      },
      resolveSignerProfileBySignerValue: function (signerValue) {
        var value = String(signerValue || "").trim().toUpperCase();
        var i = 0;
        var row = null;
        if (!value) return null;
        for (i = 0; i < (this.signerProfiles || []).length; i += 1) {
          row = this.signerProfiles[i];
          if (!row) continue;
          if (String(row.EmployeeCode || "").trim().toUpperCase() === value) return row;
          if (String(row.Email || "").trim().toUpperCase() === value) return row;
        }
        return null;
      },
      resolveSignerProfileByPersonName: function (personName) {
        var target = String(personName || "").trim().toUpperCase();
        var i = 0;
        var row = null;
        if (!target) return null;
        for (i = 0; i < (this.signerProfiles || []).length; i += 1) {
          row = this.signerProfiles[i];
          if (!row) continue;
          if (String(row.FullName || "").trim().toUpperCase() === target) return row;
        }
        return null;
      },
      resolveSignerProfileFromSigner: function (signer) {
        var profile = null;
        if (!signer) return null;
        profile = this.resolveSignerProfileBySignerValue(signer.personCode || "");
        if (profile) return profile;
        profile = this.resolveSignerProfileBySignerValue(signer.roleCode || "");
        if (profile) return profile;
        return this.resolveSignerProfileByPersonName(signer.personName || "");
      },
      resolveSmartCASignerValue: function (profile, signer) {
        var value = profile ? (profile.EmployeeCode || profile.Email || "") : "";
        if (!value && signer) value = String(signer.personCode || signer.roleCode || "").trim();
        return String(value || "").trim();
      },
      isSignerProfileCertUsable: function (profile) {
        var now = Date.now();
        var validFrom = null;
        var validTo = null;
        if (!profile) return false;
        if (!Number(profile.IsActive || 0) || !Number(profile.CertIsActive || 0)) return false;
        if (!String(profile.CertSerial || "").trim()) return false;
        validFrom = profile.CertValidFrom ? new Date(profile.CertValidFrom).getTime() : null;
        validTo = profile.CertValidTo ? new Date(profile.CertValidTo).getTime() : null;
        if (validFrom && !Number.isNaN(validFrom) && now < validFrom) return false;
        if (validTo && !Number.isNaN(validTo) && now > validTo) return false;
        return true;
      },
      mapSignMethodToEcontract: function (method) {
        var raw = String(method || "").toLowerCase();
        if (raw.indexOf("otp email") >= 0) return "3";
        if (raw.indexOf("otp sms") >= 0) return "2";
        if (raw.indexOf("ký ảnh") >= 0 || raw.indexOf("image") >= 0) return "1";
        if (raw.indexOf("smartca") >= 0) return "4";
        return "4";
      },
      normalizeEcontractPositionInt: function (value, fallback) {
        var parsed = Number(value);
        if (!Number.isFinite(parsed)) return Number(fallback || 0) || 0;
        return Math.max(0, Math.round(parsed));
      },
      isSameEcontractSignerKey: function (left, right) {
        return String(left || "").trim().toUpperCase() === String(right || "").trim().toUpperCase();
      },
      resolveEcontractSignerBoxes: function (signer, payload) {
        var boxes = payload && payload.SignBoxes ? payload.SignBoxes : [];
        var matches = [];
        var signerValue = String(signer && signer.SignerValue || "").trim();
        var signerName = String(signer && signer.PersonName || "").trim();
        var signerOrder = Number(signer && signer.SignOrder || 0);
        var i = 0;
        var box = null;
        for (i = 0; i < boxes.length; i += 1) {
          box = boxes[i] || {};
          if (signerOrder > 0 && Number(box.SignerOrder || 0) === signerOrder) {
            matches.push(box);
            continue;
          }
          if (signerValue && this.isSameEcontractSignerKey(box.SignerValue, signerValue)) {
            matches.push(box);
            continue;
          }
          if (signerName && this.isSameEcontractSignerKey(box.PersonName, signerName)) {
            matches.push(box);
          }
        }
        matches.sort(function (a, b) {
          var pageA = Number(a && a.PageNo || 1) || 1;
          var pageB = Number(b && b.PageNo || 1) || 1;
          if (pageA !== pageB) return pageA - pageB;
          if (Number(a && a.BoxOrder || 0) !== Number(b && b.BoxOrder || 0)) {
            return Number(a && a.BoxOrder || 0) - Number(b && b.BoxOrder || 0);
          }
          return Number(a && a.PosY || 0) - Number(b && b.PosY || 0);
        });
        return matches;
      },
      buildEcontractSignerPositionRows: function (signer, payload) {
        var matches = this.resolveEcontractSignerBoxes(signer, payload);
        var rows = [];
        var i = 0;
        var box = null;
        for (i = 0; i < matches.length; i += 1) {
          box = matches[i] || {};
          rows.push({
            p_stt_trang: this.normalizeEcontractPositionInt(box.PageNo, 1),
            p_toado_x: this.normalizeEcontractPositionInt(box.PosX, 0),
            p_toado_y: this.normalizeEcontractPositionInt(box.PosY, 0),
            p_chieudai_w: this.normalizeEcontractPositionInt(box.BoxWidth != null ? box.BoxWidth : box.Width, 0),
            p_chieucao_h: this.normalizeEcontractPositionInt(box.BoxHeight != null ? box.BoxHeight : box.Height, 0),
            p_flag_bb_codinh: 1
          });
        }
        return rows;
      },
      buildEcontractSignerUpdatePayload: function (hopDongId, detailIds, payload) {
        var signers = payload && payload.Signers ? payload.Signers : [];
        var i = 0;
        var profile = null;
        var detailRows = [];
        var signerRows = [];
        var detailIndex = 0;
        var positionRows = [];
        detailIds = Array.isArray(detailIds) ? detailIds : [];
        for (i = 0; i < signers.length; i += 1) {
          profile = this.resolveSignerProfileBySignerValue(signers[i].SignerValue);
          positionRows = this.buildEcontractSignerPositionRows(signers[i], payload);
          signerRows.push({
            p_tk_kh_id: null,
            p_ten_taikhoan: String(signers[i].PersonName || (profile && profile.FullName) || ""),
            p_email: String((profile && profile.Email) || ""),
            p_sdt: String((profile && profile.Phone) || (profile && profile.Mobile) || ""),
            p_tinnhan: "",
            p_thoigian_xuly: null,
            p_flag_chuyenky: 0,
            p_flag_themky: 0,
            p_vaitro_ky_id: 0,
            p_ht_ky: this.mapSignMethodToEcontract(signers[i].SignMethod),
            p_thutu_bb_ky: i + 1,
            p_luong_nguoiky_id: null,
            p_thutu_ky: i + 1,
            p_flag_ky_tuantu: 1,
            p_ct_vitri: positionRows
          });
        }
        for (detailIndex = 0; detailIndex < detailIds.length; detailIndex += 1) {
          detailRows.push({
            p_hd_chitiet_id: Number(detailIds[detailIndex] || 0),
            p_ct_nk: signerRows
          });
        }
        return {
          p_hop_dong_id: Number(hopDongId || 0),
          p_ds_nguoi_ky: detailRows
        };
      },
      submitToEcontract: async function (payload) {
        var provider = this.normalizeContractProvider(payload && payload.ContractProvider || "");
        var wesignResponse = null;
        var token = "";
        var response = null;
        var hopDongId = 0;
        var detailIds = [];
        var signerPayload = null;
        if (provider === "AMIS_WESIGN") {
          wesignResponse = await this.econtractRequest("POST", this.eContractApiMap.wesignCreateFromFile, await this.validateWeSignPayload(payload), "");
          return {
            provider: provider,
            response: wesignResponse,
            documentId: this.extractFirstUuidByKeys(wesignResponse, function (key) {
              return /documentid|document_id|id/i.test(String(key || ""));
            })
          };
        }
        token = await this.loginEcontract();
        if (payload.FileMethod === "TEMPLATE" && payload.TemplateID) {
          response = await this.econtractRequest("POST", this.eContractApiMap.createFromTemplate, this.buildEcontractTemplatePayload(payload), token);
        } else {
          response = await this.econtractRequest("POST", this.eContractApiMap.createFromFile, await this.buildEcontractFilePayload(payload), token);
        }
        hopDongId = this.extractHopDongId(response);
        detailIds = this.extractEcontractDetailIds(response);
        if (Number(hopDongId || 0) <= 0) throw new Error("Tạo hợp đồng eContract chưa trả về HopDongId, không thể đồng bộ người ký.");
        if (!detailIds.length) detailIds = await this.fetchEcontractDetailIds(hopDongId, token);
        if (!detailIds.length) throw new Error("eContract chưa trả về HD_CHITIET_ID hợp lệ, đã chặn gửi update-signers để tránh payload p_hd_chitiet_id = 0.");
        signerPayload = this.buildEcontractSignerUpdatePayload(hopDongId, detailIds, payload);
        if (signerPayload.p_ds_nguoi_ky && signerPayload.p_ds_nguoi_ky.length > 0) {
          await this.econtractRequest("POST", this.eContractApiMap.updateSigners, signerPayload, token);
        }
        return { provider: provider || "VNPT_ECONTRACT", token: token, hopDongId: hopDongId, detailIds: detailIds, response: response };
      }
    }
  }
  if (typeof window !== "undefined") {
    window.__WF_REQUEST_CREATE_ECONTRACT_MIXIN__ = wfRequestCreateEcontractMixin;
  }
}
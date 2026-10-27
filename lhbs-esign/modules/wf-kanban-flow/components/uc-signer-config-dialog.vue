<template>
	<v-dialog v-model="showDialog" max-width="800" persistent>
    <v-card class="rounded-lg overflow-hidden border shadow-lg">
      <v-card-title class="bg-primary text-white d-flex align-center py-4 px-5">
        <v-icon start size="22" class="mr-2">mdi-account-edit-outline</v-icon>
        <span class="text-subtitle-1 font-weight-bold">Cấu hình người ký quy trình</span>
      </v-card-title>

      <v-card-text class="pa-5" style="max-height: 60vh; overflow-y: auto;">
        <div v-if="isLoading" class="d-flex align-center justify-center pa-10">
          <v-progress-circular indeterminate color="primary"></v-progress-circular>
        </div>
        <div v-else>
          <uc-request-signer-config :create-mode="'TEMPLATE_FLOW'" :form="form" :role-options="roleOptions"
            :sign-method-options="availableSignMethodOptions" :signer-profiles="signerProfiles"
            :require-cert-for-smartca="executionEngine === 'SMARTCA'" @add-signer="addSigner"
            @remove-signer="removeSigner" @update-signer-role="updateSignerRole"
            @update-signer-person="updateSignerPerson" @signer-method-changed="onSignerMethodChanged" />
        </div>
      </v-card-text>

      <v-divider />

      <v-card-actions class="px-5 py-3 bg-light">
        <v-btn class="wf-btn" variant="outlined" color="grey" :disabled="isSaving" @click="close">
          Hủy
        </v-btn>
        <v-spacer />
        <v-btn class="wf-btn" color="primary" variant="flat" :loading="isSaving" @click="saveSignersAndProceed">
          Lưu & Ký số
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
	export default {
		name: "uc-signer-config-dialog",
  data: function () {
    return {
      showDialog: false,
      instanceId: null,
      executionEngine: "SMARTCA",
      externalContractId: 0,
      isLoading: false,
      isSaving: false,
      roleOptions: [],
      signerProfiles: [],
      signBoxes: [],
      signMethodOptions: ["SmartCA (Ký số)", "eContract - OTP Email", "eContract - OTP SMS", "eContract - Ký ảnh", "eContract - SmartCA App"],
      form: {
        signers: [],
        sequential: true,
        notifyEmail: true,
        requireOtpConfirm: false
      },
      signerSeed: 0,
      targetStepId: null,
      econtractAuthCache: null,
      eContractApiMap: {
        authLogin: "/api/econtract/auth/login",
        detail: "/api/econtract/contracts/{hopDongId}/detail",
        updateSigners: "/api/econtract/contracts/update-signers"
      }
    }
  },
  computed: {
    availableSignMethodOptions: function () {
      var self = this;
      if (this.executionEngine === "ECONTRACT") {
        return this.signMethodOptions.filter(function (item) {
          return self.isEContractMethod(item);
        });
      }
      return this.signMethodOptions.filter(function (item) {
        return self.isSmartCAMethod(item);
      });
    }
  },
  methods: {
    open: async function (instanceId, currentSigners, signBoxes, executionEngine, externalContractId, targetStepId, definitionId, fieldValues) {
      this.instanceId = instanceId
      this.executionEngine = executionEngine || "SMARTCA"
      this.externalContractId = Number(externalContractId || 0)
      this.signBoxes = signBoxes || []
      this.targetStepId = targetStepId || null
      this.showDialog = true
      this.isLoading = true

      try {
        await Promise.all([
          this.loadRoles(),
          this.loadSignerProfiles()
        ])

        var targetStepOrder = null
        var defDetail = null
        if (definitionId) {
          var rawDef = await apiCallAsync("WF_Definition_GetDetail", { DefinitionID: definitionId })
          if (rawDef) {
            var stepRows = rawDef[1] || []
            var stepMap = {}
            var i = 0
            for (i = 0; i < stepRows.length; i += 1) {
              stepRows[i].Signers = []
              stepMap[stepRows[i].StepDefID] = stepRows[i]
            }
            if (rawDef[3]) {
              for (i = 0; i < rawDef[3].length; i += 1) {
                if (stepMap[rawDef[3][i].StepDefID]) {
                  stepMap[rawDef[3][i].StepDefID].Signers.push(rawDef[3][i])
                }
              }
            }
            defDetail = {
              Steps: stepRows
            }
          }
          if (defDetail && defDetail.Steps && targetStepId) {
            var targetStep = defDetail.Steps.find(function (step) {
              return Number(step.StepDefID) === Number(targetStepId)
            })
            if (targetStep) {
              targetStepOrder = targetStep.StepOrder
            }
          }
        }

        var signersToInit = []
        if ((!currentSigners || currentSigners.length === 0) && defDetail) {
          var defaultSigners = this.buildSignersFromDetail(defDetail)
          signersToInit = defaultSigners
        } else {
          signersToInit = currentSigners || []
        }

        if (targetStepOrder != null) {
          var filtered = signersToInit.filter(function (s) {
            return Number(s.StepOrder || s.stepOrder || 0) === Number(targetStepOrder)
          })
          if (filtered.length === 0 && defDetail) {
            var defaultSigners = this.buildSignersFromDetail(defDetail)
            filtered = defaultSigners.filter(function (s) {
              return Number(s.StepOrder || s.stepOrder || 0) === Number(targetStepOrder)
            })
          }
          // Fallback: If still empty, build signers from the existing signBoxes of this target step
          if (filtered.length === 0 && this.signBoxes && this.signBoxes.length > 0) {
            var stepBoxes = this.signBoxes.filter(function (box) {
              return Number(box.StepOrder || 0) === Number(targetStepOrder)
            })
            if (stepBoxes.length > 0) {
              var signerMap = {}
              stepBoxes.forEach(function (box) {
                var order = Number(box.SignerOrder || 0)
                if (!signerMap[order]) {
                  signerMap[order] = box
                }
              })
              var sortedOrders = Object.keys(signerMap).map(Number).sort(function (a, b) { return a - b })
              filtered = sortedOrders.map(function (order) {
                var box = signerMap[order]
                return {
                  StepOrder: box.StepOrder,
                  SignerOrder: box.SignerOrder,
                  SignerType: box.SignerType || "ROLE",
                  SignerValue: box.SignerValue || "",
                  ResolvedPersonID: box.SignerValue || "",
                  ResolvedPersonName: box.PersonName || "",
                  SignMethod: box.SignMethod || "smartca",
                  Status: "PENDING"
                }
              })
            }
          }
          signersToInit = filtered
        }

        this.initFormSigners(signersToInit, fieldValues)
      } catch (err) {
        console.error(err)
        if (showToast && showToast.error) showToast.error("Lỗi khi tải danh mục người ký.")
      } finally {
        this.isLoading = false
      }
    },
    close: function () {
      this.showDialog = false;
    },
    loadRoles: async function () {
      var rows = await apiCallAsync("WF_RoleMapping_GetList", {});
      this.roleOptions = this.normalizeRoles(rows);
    },
    loadSignerProfiles: async function () {
      var rows = await apiCallAsync("WF_SignerProfile_GetList", {});
      this.signerProfiles = (rows || []).filter(function (item) {
        return Number(item.IsActive || 0) === 1 && Number(item.CertIsActive || 0) === 1;
      });
    },
    normalizeRoles: function (rows) {
      return (rows || []).map(function (item) {
        return {
          RoleCode: item.RoleCode,
          RoleName: item.RoleName,
          DefaultPersonName: item.DefaultPersonName || "",
          DepartmentName: item.DepartmentName || "",
          IsActive: item.IsActive === true || item.IsActive === 1
        };
      }).filter(function (item) {
        return item.IsActive;
      });
    },
    buildSignersFromDetail: function (detail) {
      var rows = [];
      var i = 0;
      var j = 0;
      var role = null;
      var profile = null;
      var personName = "";
      if (!detail || !detail.Steps) return rows;
      for (i = 0; i < detail.Steps.length; i += 1) {
        if (!detail.Steps[i].Signers || detail.Steps[i].Signers.length === 0) continue;
        for (j = 0; j < detail.Steps[i].Signers.length; j += 1) {
          role = this.findRoleByCode(detail.Steps[i].Signers[j].SignerValue);
          personName = role ? role.DefaultPersonName : detail.Steps[i].Signers[j].SignerValue;
          profile = this.resolveSignerProfileByPersonName(personName);
          rows.push({
            localId: "seed-" + detail.Steps[i].StepOrder + "-" + j,
            stepOrder: detail.Steps[i].StepOrder,
            stepName: detail.Steps[i].StepName,
            roleCode: detail.Steps[i].Signers[j].SignerValue,
            roleName: role ? role.RoleName : detail.Steps[i].Signers[j].SignerValue,
            personName: personName || "",
            personCode: profile ? (profile.EmployeeCode || profile.Email || "") : "",
            departmentName: role ? role.DepartmentName : (profile ? (profile.DepartmentName || "") : ""),
            method: this.formatSignMethod(detail.Steps[i].Signers[j].SignMethod),
            system: detail.Steps[i].SignSystem || "",
            signerType: detail.Steps[i].Signers[j].SignerType || "ROLE"
          });
        }
      }
      return rows;
    },
    formatSignMethod: function (value) {
      var map = {
        smartca: "SmartCA (Ký số)",
        otp_email: "eContract - OTP Email",
        otp_sms: "eContract - OTP SMS",
        image: "eContract - Ký ảnh"
      };
      return map[value] || value || "SmartCA (Ký số)";
    },
    initFormSigners: function (currentSigners, fieldValues) {
      const self = this
      this.signerSeed = 0
      this.form.signers = (currentSigners || []).map(function (s, index) {
        self.signerSeed += 1
        const signerType = s.SignerType || s.signerType || "ROLE"
        const rCode = s.RoleCode || s.roleCode || s.SignerValue || ""
        let pCode = s.ResolvedPersonID || s.personCode || (signerType === "USER" ? s.SignerValue : "") || ""
        let pName = s.ResolvedPersonName || s.personName || ""

        if (fieldValues) {
          const signerStepOrder = Number(s.StepOrder || s.stepOrder || 0)
          const stepBoxes = (self.signBoxes || []).filter(function (box) {
            return Number(box.StepOrder || 0) === signerStepOrder
          })
          let matchedBox = stepBoxes.find(function (box) {
            return Number(box.SignerOrder || 0) === (index + 1)
          })
          if (!matchedBox) {
            matchedBox = stepBoxes.find(function (box) {
              return String(box.SignerValue || "").trim().toUpperCase() === String(rCode || "").trim().toUpperCase()
            })
          }
          if (matchedBox && matchedBox.LabelText) {
            // Try fieldValues with the raw LabelText key first,
            // then strip ###...### or {{...}} wrappers to get the plain field name
            var labelKey = matchedBox.LabelText
            var labelVal = fieldValues[labelKey]
            if (!labelVal) {
              var mLabel = labelKey.match(/^###(.+)###$/) || labelKey.match(/^\{\{(.+)\}\}$/)
              if (mLabel) labelVal = fieldValues[mLabel[1]]
            }
            if (labelVal) {
              const val = String(labelVal).trim()
              if (val) {
                pCode = val
                const targetProfile = self.resolveSignerProfileBySignerValue(pCode)
                if (targetProfile) {
                  pName = targetProfile.FullName
                }
              }
            }
          }
        }

        const role = self.findRoleByCode(rCode)
        const profile = self.resolveSignerProfileBySignerValue(pCode) || self.resolveSignerProfileByPersonName(pName)
        if (profile) {
          pName = profile.FullName || pName
          pCode = profile.EmployeeCode || profile.Email || pCode
        }
        if (signerType === "ROLE" && role) {
          if (!pName) pName = role.DefaultPersonName
          if (!pCode) {
            const defaultProfile = self.resolveSignerProfileByPersonName(role.DefaultPersonName)
            if (defaultProfile) {
              pCode = defaultProfile.EmployeeCode || defaultProfile.Email || ""
            }
          }
        }
        const m = s.SignMethod || s.method || (self.executionEngine === "ECONTRACT" ? "eContract - OTP Email" : "SmartCA (Ký số)")
        return {
          localId: "init-signer-" + self.signerSeed,
          stepOrder: s.StepOrder || s.stepOrder || null,
          stepName: s.StepName || s.stepName || ("Bước " + (s.StepOrder || s.stepOrder || (index + 1))),
          roleCode: rCode || (role ? role.RoleCode : ""),
          roleName: s.RoleName || (role ? role.RoleName : rCode),
          personName: pName,
          personCode: pCode,
          departmentName: s.DepartmentName || s.departmentName || (profile ? (profile.DepartmentName || "") : "") || (role ? role.DepartmentName : ""),
          method: m,
          system: self.isEContractMethod(m) ? "econtract" : "smartca",
          signerType: signerType,
          signerExecId: s.SignerExecID || s.signerExecId || 0
        }
      })
    },
    isEContractMethod: function (value) {
      var method = String(value || "").toLowerCase();
      if (!method) return false;
      if (method.indexOf("econtract") >= 0) return true;
      if (method.indexOf("otp") >= 0) return true;
      if (method.indexOf("ký ảnh") >= 0) return true;
      if (method.indexOf("image") >= 0) return true;
      return false;
    },
    isSmartCAMethod: function (value) {
      var method = String(value || "").toLowerCase();
      if (!method) return false;
      return method.indexOf("smartca") >= 0 && method.indexOf("econtract") < 0;
    },
    resolveDefaultSignerMethodByEngine: function (engine) {
      var i = 0;
      if (engine === "ECONTRACT") {
        for (i = 0; i < this.signMethodOptions.length; i += 1) {
          if (this.isEContractMethod(this.signMethodOptions[i])) return this.signMethodOptions[i];
        }
        return "eContract - OTP Email";
      }
      for (i = 0; i < this.signMethodOptions.length; i += 1) {
        if (this.isSmartCAMethod(this.signMethodOptions[i])) return this.signMethodOptions[i];
      }
      return "SmartCA (Ký số)";
    },
    findRoleByCode: function (code) {
      var target = String(code || "").trim().toUpperCase();
      var i = 0;
      if (!target) return null;
      for (i = 0; i < this.roleOptions.length; i += 1) {
        if (String(this.roleOptions[i].RoleCode || "").trim().toUpperCase() === target) return this.roleOptions[i];
      }
      return null;
    },
    findFirstAvailableRole: function () {
      return this.roleOptions && this.roleOptions[0] ? this.roleOptions[0] : null;
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
    addSigner: function () {
      var role = this.findFirstAvailableRole();
      var method = this.resolveDefaultSignerMethodByEngine(this.executionEngine);
      var profile = this.resolveSignerProfileByPersonName(role ? role.DefaultPersonName : "");
      this.signerSeed += 1;
      this.form.signers.push({
        localId: "manual-" + this.signerSeed,
        stepOrder: null,
        stepName: "Ad-hoc",
        roleCode: role ? role.RoleCode : "",
        roleName: role ? role.RoleName : "",
        personName: role ? role.DefaultPersonName : "",
        personCode: profile ? (profile.EmployeeCode || profile.Email || "") : "",
        departmentName: role ? role.DepartmentName : (profile ? (profile.DepartmentName || "") : ""),
        method: method,
        system: this.isEContractMethod(method) ? "econtract" : "smartca",
        signerType: "ROLE",
        signerExecId: 0
      });
    },
    removeSigner: function (index) {
      this.form.signers.splice(index, 1);
    },
    updateSignerRole: function (signer) {
      var role = this.findRoleByCode(signer.roleCode);
      var profile = null;
      if (!role) return;
      signer.roleName = role.RoleName;
      if (!String(signer.personName || "").trim()) signer.personName = role.DefaultPersonName;
      profile = this.resolveSignerProfileByPersonName(signer.personName || role.DefaultPersonName || "");
      if (profile) {
        signer.personName = profile.FullName || signer.personName || role.DefaultPersonName;
        signer.personCode = profile.EmployeeCode || profile.Email || "";
        signer.departmentName = profile.DepartmentName || role.DepartmentName || "";
      } else {
        signer.departmentName = role.DepartmentName;
      }
    },
    updateSignerPerson: function (payload) {
      var signer = payload && payload.signer ? payload.signer : null;
      var personCode = payload && payload.personCode ? String(payload.personCode).trim() : "";
      var profile = null;
      if (!signer) return;
      if (!personCode) {
        signer.personCode = "";
        return;
      }
      profile = this.resolveSignerProfileBySignerValue(personCode);
      if (!profile) {
        signer.personCode = personCode;
        return;
      }
      signer.personCode = profile.EmployeeCode || profile.Email || personCode;
      signer.personName = profile.FullName || signer.personName || "";
      if (!signer.departmentName) signer.departmentName = profile.DepartmentName || "";
      if (this.executionEngine === "SMARTCA") {
        if (this.isSignerProfileCertUsable(profile)) {
          signer.method = this.resolveDefaultSignerMethodByEngine("SMARTCA");
        } else {
          signer.method = "";
          if (showToast && showToast.error) {
            showToast.error("Người ký chưa có chứng thư số SmartCA hợp lệ.");
          }
        }
      }
    },
    onSignerMethodChanged: function () {
      // Nothing special here
    },
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
    resolveEcontractSignerBoxes: function (signer, signBoxes) {
      var boxes = signBoxes || [];
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
    buildEcontractSignerPositionRows: function (signer, signBoxes) {
      var matches = this.resolveEcontractSignerBoxes(signer, signBoxes);
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
    buildEcontractSignerUpdatePayload: function (hopDongId, detailIds, signers, signBoxes) {
      var i = 0;
      var profile = null;
      var detailRows = [];
      var signerRows = [];
      var detailIndex = 0;
      var positionRows = [];
      detailIds = Array.isArray(detailIds) ? detailIds : [];
      for (i = 0; i < signers.length; i += 1) {
        profile = this.resolveSignerProfileBySignerValue(signers[i].SignerValue);
        positionRows = this.buildEcontractSignerPositionRows(signers[i], signBoxes);
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
    saveSignersAndProceed: async function () {
      var self = this
      this.isSaving = true

      try {
        if (this.executionEngine === "ECONTRACT" && this.externalContractId > 0) {
          var token = await this.loginEcontract()
          var detailIds = await this.fetchEcontractDetailIds(this.externalContractId, token)
          
          var signersPayload = (this.form.signers || []).map(function (s, index) {
            var profile = self.resolveSignerProfileFromSigner(s)
            var isSmartCA = self.isSmartCAMethod(s.method)
            var signerValue = isSmartCA
              ? self.resolveSmartCASignerValue(profile, s)
              : (String(s.roleCode || s.personCode || "").trim())
            return {
              SignOrder: index + 1,
              SignerOrder: index + 1,
              SignerValue: signerValue,
              PersonName: (profile && profile.FullName) || s.personName || "",
              SignMethod: s.method,
              DepartmentName: (profile && profile.DepartmentName) || s.departmentName || ""
            }
          })

          var signerPayload = this.buildEcontractSignerUpdatePayload(this.externalContractId, detailIds, signersPayload, this.signBoxes)
          if (signerPayload.p_ds_nguoi_ky && signerPayload.p_ds_nguoi_ky.length > 0) {
            await this.econtractRequest("POST", this.eContractApiMap.updateSigners, signerPayload, token)
          }

          // Đồng bộ eContract về database
          await apiCallAsync("WF_Request_SyncEContract", {
            InstanceID: this.instanceId,
            HopDongID: this.externalContractId
          })

          if (this.targetStepId) {
            await apiCallAsync("WF_Instance_MoveStep", {
              InstanceID: this.instanceId,
              ToStepDefID: Number(this.targetStepId)
            })
          }
        } else {
          // Internal SMARTCA / Ad-hoc:
          // 1. MoveStep TRƯỚC (tạo execution + signer cho bước đích)
          if (this.targetStepId) {
            await apiCallAsync("WF_Instance_MoveStep", {
              InstanceID: this.instanceId,
              ToStepDefID: Number(this.targetStepId)
            })
          }

          // 2. Reload detail để lấy SignerExecID mới
          var detailData = await apiCallAsync("WF_Request_GetDetail", { InstanceID: this.instanceId })
          var updatedSigners = detailData && detailData[2] ? detailData[2] : []
          var updatedSteps = detailData && detailData[1] ? detailData[1] : []

          // 3. Tìm StepOrder của bước đích
          var targetStepOrder = null
          var si = 0
          for (si = 0; si < updatedSteps.length; si += 1) {
            if (Number(updatedSteps[si].StepDefID || 0) === Number(this.targetStepId || 0)) {
              targetStepOrder = Number(updatedSteps[si].StepOrder || 0)
              break
            }
          }

          // 4. Lọc signer thuộc bước đích
          var newStepSigners = updatedSigners.filter(function (s) {
            return targetStepOrder != null && Number(s.StepOrder || 0) === targetStepOrder
          })

          // 5. Lọc form.signers thuộc bước đích (dựa vào stepOrder khớp targetStepOrder)
          //    Nếu không lọc được thì dùng tất cả form.signers
          var targetFormSigners = this.form.signers.filter(function (s) {
            return targetStepOrder != null && Number(s.stepOrder || 0) === targetStepOrder
          })
          if (!targetFormSigners.length) {
            // fallback: dùng tất cả form.signers (trường hợp stepOrder chưa được set)
            targetFormSigners = this.form.signers.slice()
          }

          // 6. Gán PIC cho từng signer theo thứ tự
          var i = 0
          console.log('[SignerConfig] targetStepOrder:', targetStepOrder, 'newStepSigners:', newStepSigners.length, 'targetFormSigners:', targetFormSigners.length)
          for (i = 0; i < targetFormSigners.length; i += 1) {
            var s = targetFormSigners[i]
            var personCode = String(s.personCode || "").trim()
            console.log('[SignerConfig] signer[' + i + '] personCode:', personCode, 'personName:', s.personName, 'stepOrder:', s.stepOrder)
            if (!personCode) continue

            // Match 1: Dùng signerExecId từ form signer nếu có (chính xác nhất)
            var matchSigner = null
            var j = 0
            var signerExecId = Number(s.signerExecId || 0)
            if (signerExecId > 0) {
               for (j = 0; j < newStepSigners.length; j += 1) {
                 if (Number(newStepSigners[j].SignerExecID || 0) === signerExecId) {
                   matchSigner = newStepSigners[j]
                   break
                 }
               }
            }
            // Match 2: Fallback theo SignerOrder (1-based index trong targetFormSigners)
            if (!matchSigner) {
               for (j = 0; j < newStepSigners.length; j += 1) {
                 if (Number(newStepSigners[j].SignerOrder || 0) === (i + 1)) {
                   matchSigner = newStepSigners[j]
                   break
                 }
               }
            }

            console.log('[SignerConfig] matchSigner:', matchSigner ? matchSigner.SignerExecID : null)
            if (matchSigner && matchSigner.SignerExecID) {
               await apiCallAsync("WF_Instance_AssignPIC", {
                 InstanceID: this.instanceId,
                 AssignTo: personCode,
                 StepDefID: this.targetStepId ? Number(this.targetStepId) : null,
                 SignerExecID: Number(matchSigner.SignerExecID)
               })
               console.log('[SignerConfig] AssignPIC done for', personCode, 'SignerExecID:', matchSigner.SignerExecID)
            } else {
               console.warn('[SignerConfig] No matchSigner found for targetFormSigner[' + i + '] SignerOrder=' + (i+1))
            }
          }

          // 7. Vô hiệu hóa các signer exec dư thừa không nằm trong danh sách cấu hình mới của người dùng
          var activeSignerExecIds = targetFormSigners.map(function (s, idx) {
            var match = newStepSigners.find(function (ns) {
              return Number(ns.SignerExecID || 0) === Number(s.signerExecId || 0) || Number(ns.SignerOrder || 0) === (idx + 1)
            })
            return match ? Number(match.SignerExecID || 0) : 0
          }).filter(function (id) { return id > 0 })

          for (var k = 0; k < newStepSigners.length; k += 1) {
            var nsId = Number(newStepSigners[k].SignerExecID || 0)
            if (activeSignerExecIds.indexOf(nsId) < 0) {
              // API helper gán PIC rỗng cho signer để vô hiệu hoá nó
              await apiCallAsync("WF_Instance_AssignPIC", {
                InstanceID: this.instanceId,
                AssignTo: "",
                StepDefID: this.targetStepId ? Number(this.targetStepId) : null,
                SignerExecID: nsId
              }).catch(function (e) {})
            }
          }
        }

        if (showToast && showToast.success) showToast.success("Lưu cấu hình người ký thành công!")
        this.showDialog = false
        this.$emit("saved")
      } catch (err) {
        console.error(err)
        var msg = err && err.responseJSON ? err.responseJSON.Message : (err && err.message ? err.message : "Không thể lưu cấu hình người ký.")
        if (showToast && showToast.error) showToast.error(msg)
      } finally {
        this.isSaving = false
      }
    }
  }
	}
</script>
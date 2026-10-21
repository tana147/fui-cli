<template>
	<v-dialog v-model="dialog" transition="dialog-bottom-transition" fullscreen persistent>
    <v-card class="d-flex flex-column decision-modal-card-fullscreen uc-decision-scope">
      <v-toolbar color="primary" dark class="uc-decision-toolbar flex-grow-0 flex-shrink-0">
        <h3 class="mb-0">Thêm mới quyết định</h3>
        <v-spacer></v-spacer>
        <v-btn icon dark @click="onClose">
          <v-icon>mdi-close</v-icon>
        </v-btn>
      </v-toolbar>

      <v-card-text class="mt-3 flex-grow-1 overflow-y-auto">
        <h3 class="primary--text mb-3">Thông tin quyết định</h3>
        <v-row>
          <v-col cols="1">
            <v-autocomplete v-model="addData.Decision_Type" outlined label="Hệ đào tạo" item-text="VALUE"
              item-value="KEY" dense :items="heDaoTao" hide-details />
          </v-col>

          <v-col cols="2">
            <v-autocomplete v-model="addData.Decision_NganhID" outlined label="Ngành học" dense
              :items="filteredNganhArr" item-text="TenNganh" item-value="NganhID" hide-details />
          </v-col>

          <v-col cols="1">
            <v-select v-model="addData.Decision_NienKhoa" outlined color="success" dense label="Niên khóa"
              :items="nienKhoaArr" hide-details item-text="Nien_Khoa" item-value="Nien_Khoa"
              :disabled="addData.Decision_NganhID === null" />
          </v-col>
          <v-col cols="1">
            <v-text-field v-model="addData.Decision_MaSo" outlined color="success" dense label="Mã ngành"
              placeholder="Mã ngành" hide-details disabled />
          </v-col>
          <v-col cols="1">
            <v-text-field v-model="addData.Decision_Dot" outlined color="success" dense label="Đợt"
              placeholder="Nhập đợt" hide-details />
          </v-col>
          <v-col cols="3">
            <v-select v-model="decisionTypeSelect" :items="decisionTypeList" item-text="text" item-value="value"
              label="Loại quyết định" outlined dense hide-details />
          </v-col>
        </v-row>

        <div v-if="addData.Decision_NganhID == '106' || addData.Decision_NganhID == '102'">
          <v-radio-group v-model="thsType" row mandatory>
            <v-radio value="1" label="Thạc sĩ ứng dụng" />
            <v-radio value="2" label="Thạc sĩ nghiên cứu" />
          </v-radio-group>
        </div>

        <v-row class="mt-3">
          <v-col>
            <uc-student-list-add :nienkhoa="addData.Decision_NienKhoa" :thstype="thsType"
              :nganhid="addData.Decision_NganhID" :isdelete="isDelete" @on-change-data="handleStudentChange" />
          </v-col>
        </v-row>
      </v-card-text>

      <v-card-actions class="px-4 pb-4 flex-grow-0 flex-shrink-0">
        <v-spacer></v-spacer>
        <div class="uc-decision-select-nien-khoa-wrap mr-3 max-width-nien-khoa">
          <v-select v-model="addData.Decision_Ins_NienKhoa" outlined color="success" dense label="Niên khóa QĐ"
            :items="nienKhoaArr" hide-details item-text="Nien_Khoa" item-value="Nien_Khoa"
            :disabled="addData.Decision_NganhID === null" />
        </div>
        <v-btn color="success" :disabled="selectedStudents.length === 0" @click="onAddDecision">
          <v-icon left>mdi-plus</v-icon>Tạo
        </v-btn>
        <v-btn color="info" :disabled="selectedStudents.length === 0" @click="addAndPrint">
          <v-icon left>mdi-printer</v-icon>Tạo và In
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-add",
  props: {
    value: {
      type: Boolean,
      default: false,
    },
    nganhArr: {
      type: Array,
      default: () => [],
    },
    heDaoTao: {
      type: Array,
      default: () => [],
    },
  },
  emits: ["input", "on-reload"],
  data() {
    return {
      addData: {
        Decision_TieuDe: "",
        Decision_Nganh: "",
        Decision_NienKhoa: "",
        Decision_Ins_NienKhoa: "",
        Decision_Dot: "",
        Decision_MaSo: "",
        Decision_Type: "C",
        Decision_NganhID: null,
        Decision_Description: "",
      },
      thsType: "1",
      selectedStudents: [],
      nienKhoaArr: [],
      isDelete: false,
      decisionTypeSelect: 1,
      decisionTypeList: [
        {
          text: "Giao đề tài",
          tieuDe: "Về việc công nhận tên đề tài và giảng viên hướng dẫn luận văn thạc sĩ",
          value: 1,
        },
        {
          text: "Đổi tên đề tài",
          tieuDe: "Về việc đổi tên đề tài luận văn thạc sĩ",
          value: 2,
        },
        {
          text: "Đổi tên Giảng viên hướng dẫn",
          tieuDe: "Về việc đổi giảng viên hướng dẫn luận văn thạc sĩ",
          value: 3,
        },
        {
          text: "Điều chỉnh đề tài",
          tieuDe: "Về việc điều chỉnh tên đề tài luận văn thạc sĩ",
          value: 4,
        },
        {
          text: "Điều chỉnh giảng viên hướng dẫn",
          tieuDe: "Về việc điều chỉnh giảng viên hướng dẫn luận văn thạc sĩ",
          value: 5,
        },
        {
          text: "Đổi tên đề tài và giảng viên hướng dẫn",
          tieuDe: "Về việc đổi tên đề tài và giảng viên hướng dẫn",
          value: 6,
        },
      ],
    };
  },
  computed: {
    dialog: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit("input", val);
      },
    },
    filteredNganhArr() {
      return this.nganhArr;
    },
  },
  watch: {
    "addData.Decision_NienKhoa": function (val) {
      if (val) {
        this.addData.Decision_Ins_NienKhoa = val;
      }
    },
    "addData.Decision_NganhID": function (newVal) {
      if (newVal !== null && newVal !== undefined) {
        this.onLoadNienKhoa(newVal);
        this.addData.Decision_NienKhoa = null;

        const selectMajor = this.nganhArr.find((item) => item.NganhID === newVal);
        if (selectMajor) {
          this.addData.Decision_MaSo = selectMajor.MaNganh || "";
          this.addData.Decision_Nganh = selectMajor.OriginalName || selectMajor.TenNganh || "";
        }
      }
    },
    "addData.Decision_Type": function (val) {
      const selectedType = this.heDaoTao.find((item) => item.KEY === val);
      const filterDecision = this.decisionTypeList.find((item) => item.value === this.decisionTypeSelect);
      if (selectedType) {
        const isC = selectedType.KEY === "C";
        this.addData.Decision_TieuDe = isC
          ? (this.decisionTypeSelect == 1 ? selectedType.SUBJECT : filterDecision?.tieuDe)
          : selectedType.SUBJECT;
      }
    },
    decisionTypeSelect: function (val) {
      const selectedType = this.heDaoTao.find((item) => item.KEY === this.addData.Decision_Type);
      const filterDecision = this.decisionTypeList.find((item) => item.value === val);
      if (selectedType) {
        const isC = selectedType.KEY === "C";
        this.addData.Decision_TieuDe = isC
          ? (val == 1 ? selectedType.SUBJECT : filterDecision?.tieuDe)
          : selectedType.SUBJECT;
      }
    },
    thsType: function (val) {
      if (this.addData.Decision_NganhID == "106" || (this.addData.Decision_NganhID == "102" && val)) {
        this.onLoadNienKhoa(this.addData.Decision_NganhID);
      }
    },
  },
  methods: {
    onClose() {
      this.isDelete = true;
      this.$nextTick(() => {
        this.resetAddData();
        this.isDelete = false;
        this.dialog = false;
      });
    },

    resetAddData() {
      this.addData.Decision_TieuDe = "";
      this.addData.Decision_Nganh = "";
      this.addData.Decision_NganhID = null;
      this.addData.Decision_NienKhoa = "";
      this.addData.Decision_Ins_NienKhoa = "";
      this.addData.Decision_Dot = "";
      this.addData.Decision_MaSo = "";
      this.addData.Decision_Type = "C";
      this.addData.Decision_Description = "";
      this.decisionTypeSelect = 1;
      this.selectedStudents = [];
      this.nienKhoaArr = [];
    },

    handleStudentChange(students) {
      this.selectedStudents = students;
    },

    async onLoadNienKhoa(nganhID) {
      let processId = 1;
      if (this.thsType === "1") {
        if (nganhID == "102" || nganhID == "106") {
          processId = 4;
        }
      } else if (this.thsType === "2") {
        if (nganhID == "102" || nganhID == "106") {
          processId = 1;
        }
      }

      const resData = await ajaxCALLPromise("/Get_NienKhoa_StudentWaitForThesisConfirm", {
        Process_ID: processId,
        Nganh_ID: nganhID,
      });

      if (resData) {
        this.nienKhoaArr = resData;
      }
    },

    async onAddDecision() {
      if (!this.addData.Decision_Type) {
        Vue.$toast.error("Không được bỏ trống hệ đào tạo", { position: "top" });
        return;
      }
      if (this.addData.Decision_NganhID === null || this.addData.Decision_NganhID === undefined || this.addData.Decision_NganhID === "0" || this.addData.Decision_NganhID === 0) {
        Vue.$toast.error("Vui lòng chọn ngành học cụ thể", { position: "top" });
        return;
      }

      if (this.addData.Decision_NienKhoa && (this.addData.Decision_NganhID === "0" || this.addData.Decision_MaSo)) {
        const filterStudentIDs = this.selectedStudents.map((item) => item.Student_ID);
        const type =
          this.addData.Decision_Type === "C" || this.addData.Decision_Type === "N"
            ? "Cao Học"
            : this.addData.Decision_Type;

        if (filterStudentIDs.length > 0) {
          const res = await ajaxCALLPromise("/Decision_Ins", {
            Decision_Obj: {
              Decision_TieuDe: this.addData.Decision_TieuDe,
              Decision_NganhID: this.addData.Decision_NganhID,
              Decision_Nganh: this.addData.Decision_Nganh,
              Decision_NienKhoa: this.addData.Decision_Ins_NienKhoa,
              Decision_Dot: this.addData.Decision_Dot,
              Decision_MaSo: this.addData.Decision_MaSo,
              Decision_Type: type,
              Decision_Description: this.addData.Decision_Description,
              Decision_TemplateID: 1,
            },
            Student_Obj: {
              Student_ID: filterStudentIDs,
            },
          });
          if (res) {
            Vue.$toast.success("Cập nhật thành công", { position: "top" });
            this.$emit("on-reload");
            this.onClose();
          }
        } else {
          Vue.$toast.error("Chưa chọn học viên", { position: "top" });
        }
      } else {
        Vue.$toast.error("Chưa nhập đủ Đợt, Niên Khóa, Mã ngành", { position: "top" });
      }
    },

    async addAndPrint() {
      if (!this.addData.Decision_Nganh) {
        Vue.$toast.error("Không tìm thấy ngành", { position: "top" });
        return;
      }

      if (this.addData.Decision_Type && (this.addData.Decision_NganhID !== null && this.addData.Decision_NganhID !== undefined && this.addData.Decision_NganhID !== "0" && this.addData.Decision_NganhID !== 0)) {
        if (this.addData.Decision_NienKhoa && (this.addData.Decision_NganhID === "0" || this.addData.Decision_MaSo)) {
          const filterStudentIDs = this.selectedStudents.map((item) => item.Student_ID);
          const type =
            this.addData.Decision_Type === "C" || this.addData.Decision_Type === "N"
              ? "Cao Học"
              : this.addData.Decision_Type;

          if (filterStudentIDs.length > 0) {
            const res = await ajaxCALLPromise("/Decision_Ins", {
              Decision_Obj: {
                Decision_TieuDe: this.addData.Decision_TieuDe,
                Decision_Nganh: this.addData.Decision_Nganh,
                Decision_NganhID: this.addData.Decision_NganhID,
                Decision_NienKhoa: this.addData.Decision_Ins_NienKhoa,
                Decision_Dot: this.addData.Decision_Dot,
                Decision_MaSo: this.addData.Decision_MaSo,
                Decision_Type: type,
                Decision_Description: this.addData.Decision_Description,
                Decision_TemplateID: 1,
              },
              Student_Obj: {
                Student_ID: filterStudentIDs,
              },
            });
            if (res) {
              Vue.$toast.success("Cập nhật thành công", { position: "top" });
              // Trigger parent print logic or calling local window print helper
              const decId = parseInt(res[0]?.Decision_ID || res.Decision_ID);
              if (typeof this.$parent.htmlToPdf === "function") {
                this.$parent.htmlToPdf(decId, type);
              }
              this.$emit("on-reload");
              this.onClose();
            }
          } else {
            Vue.$toast.error("Chưa chọn học viên", { position: "top" });
          }
        } else {
          Vue.$toast.error("Chưa nhập đủ Đợt, Niên Khóa, Mã ngành", { position: "top" });
        }
      } else {
        Vue.$toast.error("Vui lòng chọn ngành học cụ thể", { position: "top" });
      }
    },
  },
	}
</script>
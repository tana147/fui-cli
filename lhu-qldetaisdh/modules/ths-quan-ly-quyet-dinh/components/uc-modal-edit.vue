<template>
	<v-dialog v-model="dialog" transition="dialog-bottom-transition" fullscreen persistent>
    <v-card class="d-flex flex-column decision-modal-card-fullscreen uc-decision-scope">
      <v-toolbar color="info" dark class="uc-decision-toolbar flex-grow-0 flex-shrink-0">
        <h3 class="mb-0">Cập nhật quyết định</h3>
        <v-spacer></v-spacer>
        <v-btn icon dark @click="close">
          <v-icon>mdi-close</v-icon>
        </v-btn>
      </v-toolbar>

      <v-card-text class="mt-3 flex-grow-1 overflow-y-auto">
        <h3 class="primary--text mb-3">Thông tin quyết định</h3>
        <v-row>
          <v-col cols="2">
            <v-autocomplete v-model="localDecision.Decision_NganhID" outlined label="Lọc theo ngành" dense
              :items="filteredNganhArr" item-text="TenNganh" item-value="NganhID" hide-details
              :disabled="localDecision.Decision_Status === 3" />
          </v-col>

          <v-col cols="1">
            <v-autocomplete v-model="localDecision.Decision_NienKhoa" outlined color="success" dense label="Niên khóa"
              placeholder="Chọn niên khóa" hide-details :disabled="localDecision.Decision_Status === 3"
              :items="nienKhoaArr" item-text="Nien_Khoa" item-value="Nien_Khoa" />
          </v-col>

          <v-col cols="1">
            <v-text-field v-model="localDecision.Decision_MaSo" outlined color="success" dense label="Mã ngành"
              placeholder="Nhập mã ngành" hide-details disabled />
          </v-col>

          <v-col cols="1">
            <v-text-field v-model="localDecision.Decision_Dot" outlined color="success" dense label="Đợt"
              placeholder="Nhập đợt" hide-details :disabled="localDecision.Decision_Status === 3" />
          </v-col>

          <v-col cols="3">
            <v-select v-model="decisionTypeSelect" :items="decisionTypeList" item-text="text" item-value="value"
              label="Loại quyết định" outlined dense hide-details />
          </v-col>
        </v-row>

        <div v-if="localDecision.Decision_NganhID == 106">
          <v-radio-group v-model="thsType" row mandatory>
            <v-radio value="1" label="Thạc sĩ ứng dụng" />
            <v-radio value="2" label="Thạc sĩ nghiên cứu" />
          </v-radio-group>
        </div>

        <v-row class="mt-3">
          <v-col>
            <uc-student-edit-table v-if="localDecision.Decision_Status !== 3" :studentlist="detailStudent"
              :thstype="thsType" :nganhid="localDecision.Decision_NganhID" :detaildecision="localDecision"
              :isedit="dialog" :nienkhoa="localDecision.Decision_NienKhoa" @on-change-data="handleStudentChange" />
            <uc-student-detail-table v-else :studentlist="detailStudent" />
          </v-col>
        </v-row>
      </v-card-text>

      <v-card-actions class="px-4 pb-4 flex-grow-0 flex-shrink-0">
        <v-spacer></v-spacer>
        <div class="uc-decision-select-nien-khoa-wrap mr-3 max-width-nien-khoa">
          <v-autocomplete v-model="nienKhoaSelected" outlined color="success" dense label="Niên khóa"
            placeholder="Nhập niên khóa" hide-details :disabled="localDecision.Decision_Status === 3"
            :items="nienKhoaArr" item-text="Nien_Khoa" item-value="Nien_Khoa" />
        </div>
        <v-btn color="success" :disabled="isEmptyStudent" @click="onUpdateDecision">
          <v-icon left>mdi-update</v-icon>Cập nhật
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-edit",
  props: {
    value: {
      type: Boolean,
      default: false,
    },
    detailDecision: {
      type: Object,
      default: () => ({}),
    },
    detailStudent: {
      type: Array,
      default: () => [],
    },
    nganhArr: {
      type: Array,
      default: () => [],
    },
  },
  emits: ["input", "on-reload"],
  data() {
    return {
      localDecision: {},
      selectedStudents: [],
      nienKhoaArr: [],
      nienKhoaSelected: "",
      thsType: "1",
      decisionTypeSelect: 1,
      isEmptyStudent: false,
      decisionTypeList: [
        { text: "Giao đề tài", tieuDe: null, value: 1 },
        { text: "Đổi tên đề tài", tieuDe: "Về việc đổi tên đề tài luận văn thạc sĩ", value: 2 },
        { text: "Đổi tên Giảng viên hướng dẫn", tieuDe: "Về việc đổi giảng viên hướng dẫn luận văn thạc sĩ", value: 3 },
        { text: "Điều chỉnh đề tài", tieuDe: "Về việc điều chỉnh tên đề tài luận văn thạc sĩ", value: 4 },
        { text: "Điều chỉnh giảng viên hướng dẫn", tieuDe: "Về việc điều chỉnh giảng viên hướng dẫn luận văn thạc sĩ", value: 5 },
        { text: "Đổi tên đề tài và giảng viên hướng dẫn", tieuDe: "Về việc đổi tên đề tài và giảng viên hướng dẫn", value: 6 },
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
      return this.nganhArr.filter((item) => item.NganhID !== "0");
    },
  },
  watch: {
    value(val) {
      if (val) {
        this.localDecision = JSON.parse(JSON.stringify(this.detailDecision));
        if (this.localDecision.Decision_NganhID) {
          this.localDecision.Decision_NganhID = this.localDecision.Decision_NganhID.toString();
        }
        this.nienKhoaSelected = this.localDecision.Decision_NienKhoa || "";
        this.selectedStudents = [...this.detailStudent];

        if (this.localDecision.Decision_TieuDe) {
          const title = this.localDecision.Decision_TieuDe;
          this.decisionTypeSelect = title.includes("đổi tên đề tài")
            ? 2
            : title.includes("điều chỉnh tên đề tài")
            ? 3
            : 1;
        }
      }
    },
    "localDecision.Decision_NganhID": function (val) {
      if (val) {
        this.onLoadNienKhoa(val);
        const selectNganh = this.nganhArr.find((item) => item.NganhID === val);
        if (selectNganh) {
          this.localDecision.Decision_Nganh = selectNganh.OriginalName || selectNganh.TenNganh || "";
          this.localDecision.Decision_MaSo = selectNganh.MaNganh || "";
        }
      }
    },
    "localDecision.Decision_NienKhoa": function (val) {
      if (val) {
        this.nienKhoaSelected = val;
      }
    },
    thsType: function (val) {
      if (this.localDecision.Decision_NganhID == "106" && val) {
        this.onLoadNienKhoa("106");
      }
    },
    decisionTypeSelect: function (val) {
      const globalHeDaoTao = window.vueData?.heDaoTao || [];
      const selectedType = globalHeDaoTao.find((item) => item.KEY === this.localDecision.Decision_Type);
      const filterDecision = this.decisionTypeList.find((item) => item.value === val);
      if (selectedType) {
        const isC = selectedType.KEY === "C";
        this.localDecision.Decision_TieuDe = isC
          ? (val == 1 ? selectedType.SUBJECT : filterDecision?.tieuDe)
          : selectedType.SUBJECT;
      }
    },
  },
  methods: {
    close() {
      this.dialog = false;
    },
    handleStudentChange(students) {
      this.selectedStudents = students;
      this.isEmptyStudent = students.length === 0;
    },
    async onLoadNienKhoa(nganhID) {
      const resData = await ajaxCALLPromise("/Get_NienKhoa_StudentWaitForThesisConfirm", {
        Process_ID: nganhID == "102" || (nganhID == "106" && this.thsType === "1") ? 4 : 1,
        Nganh_ID: nganhID,
      });
      if (resData) {
        this.nienKhoaArr = resData;
      }
    },
    async onUpdateDecision() {
      if (
        this.localDecision.Decision_Nganh &&
        this.localDecision.Decision_Dot !== "" &&
        this.localDecision.Decision_NienKhoa !== "" &&
        this.localDecision.Decision_MaSo !== ""
      ) {
        const studentIDs = this.selectedStudents.map((item) => item.Student_ID);
        const res = await ajaxCALLPromise("/Decision_Udp", {
          Decision_Obj: {
            Decision_ID: this.localDecision.Decision_ID,
            Decision_TieuDe: this.localDecision.Decision_TieuDe,
            Decision_NganhID: this.localDecision.Decision_NganhID,
            Decision_Nganh: this.localDecision.Decision_Nganh,
            Decision_NienKhoa: this.nienKhoaSelected,
            Decision_Dot: this.localDecision.Decision_Dot,
            Decision_MaSo: this.localDecision.Decision_MaSo,
            Decision_Type: this.localDecision.Decision_Type,
            Decision_Description: this.localDecision.Decision_Description,
            Decision_TemplateID: 1,
          },
          Student_Obj: {
            Student_ID: studentIDs,
            Decision_ID: this.localDecision.Decision_ID,
          },
        });
        if (res) {
          Vue.$toast.success("Cập nhật thành công", { position: "top" });
          this.$emit("on-reload");
          this.close();
        }
      } else {
        Vue.$toast.error("Không được bỏ trống Ngành, Đợt, Niên khóa, Mã ngành", { position: "top" });
      }
    },
  },
	}
</script>
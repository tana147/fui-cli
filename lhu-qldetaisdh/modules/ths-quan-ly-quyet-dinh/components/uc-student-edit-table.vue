<template>
	<div>
    <v-row>
      <v-col cols="4">
        <v-card>
          <v-card-title class="primary--text mb-0 pb-0 py-2 d-flex align-center">
            <span class="text-subtitle-1 font-weight-bold mr-2">Học viên ({{ waitList.length }})</span>
            <v-btn small outlined color="primary" @click="addAllHV" class="uc-decision-btn-small mr-2 px-2">
              <v-icon left size="16">mdi-plus</v-icon> Thêm tất cả
            </v-btn>
            <v-spacer></v-spacer>
            <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Tìm kiếm" single-line hide-details
              dense variant="underlined" class="max-width-search-small" />
          </v-card-title>

          <v-data-table :items="waitList" :headers="headerTable" :search="search" dense items-per-page="-1"
            :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" height="calc(100vh - 328px)" fixed-header>
            <template v-slot:no-data>
              <c-empty-state text="Không có học viên chờ" />
            </template>
            <template v-slot:no-results>
              <c-empty-state text="Không tìm thấy học viên phù hợp" />
            </template>
            <template v-slot:item.Select="{ item }">
              <v-btn x-small fab icon @click="addHV(item)">
                <v-icon color="primary">mdi-plus</v-icon>
              </v-btn>
            </template>
            <template v-slot:item.Student_Search="{ item }">
              <span class="primary--text">
                <b>{{ item.Ho_SV }} {{ item.Ten_SV }}</b>
              </span>
              <br />
              <b>{{ item.Student_ID }}</b>
              <span class="amber--text"> [{{ item.Lop_ID }}]</span>
            </template>
            <template v-slot:item.Topic="{ item }">
              <b>{{ item.Thesis_Name }}</b>
              <br />
              <span v-if="!item.Thesises_Prof2"> GVHD: {{ item.Thesises_Prof1 }} </span>
              <span v-else>
                GVHD 1: {{ item.Thesises_Prof1 }} <br />
                GVHD 2: {{ item.Thesises_Prof2 }}
              </span>
            </template>
          </v-data-table>
        </v-card>
      </v-col>

      <v-col cols="8">
        <v-card>
          <v-card-title class="primary--text mb-0 pb-0 py-2 d-flex align-center">
            <span class="text-subtitle-1 font-weight-bold mr-2">Đã chọn ({{ localStudentList.length }})</span>
            <v-btn small outlined color="error" @click="deleteAll" class="uc-decision-btn-small mr-2 px-2">
              <v-icon left size="16">mdi-trash-can-outline</v-icon> Xóa tất cả
            </v-btn>
            <v-spacer></v-spacer>
            <v-text-field v-model="searchHV" prepend-inner-icon="mdi-magnify" label="Tìm kiếm" single-line hide-details
              dense variant="underlined" class="max-width-search-small" />
          </v-card-title>

          <v-data-table :items="localStudentList" :headers="headerSelectTable" :search="searchHV" dense
            items-per-page="-1" :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
            height="calc(100vh - 328px)" fixed-header>
            <template v-slot:no-data>
              <c-empty-state text="Chưa chọn học viên nào" />
            </template>
            <template v-slot:no-results>
              <c-empty-state text="Không tìm thấy học viên phù hợp" />
            </template>
            <template v-slot:item.Student_Search="{ item }">
              <span class="primary--text">
                <b>{{ item.Ho_SV }} {{ item.Ten_SV }}</b>
              </span>
              <br />
              <b>{{ item.Student_ID }}</b>
              <span class="amber--text"> [{{ item.Lop_ID }}]</span>
            </template>
            <template v-slot:item.Thesis_Name="{ item }">
              <b>{{ item.Thesis_Name }}</b>
              <br />
              <span v-if="!item.Thesises_Prof2"> GVHD: {{ item.Thesises_Prof1 }} </span>
              <span v-else>
                GVHD 1: {{ item.Thesises_Prof1 }} <br />
                GVHD 2: {{ item.Thesises_Prof2 }}
              </span>
            </template>
            <template v-slot:item.DelHV="{ item }">
              <v-btn x-small fab icon @click="removeHV(item)">
                <v-icon color="red darken-3">mdi-trash-can-outline</v-icon>
              </v-btn>
            </template>
          </v-data-table>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script>
	export default {
		name: "uc-student-edit-table",
  props: {
    nganhid: {
      type: [String, Number],
      default: null,
    },
    detailstudent: {
      type: Array,
      default: () => [],
    },
    detaildecision: {
      type: Object,
      default: () => ({}),
    },
    isedit: {
      type: Boolean,
      default: false,
    },
    nienkhoa: {
      type: String,
      default: "",
    },
    studentlist: {
      type: Array,
      default: () => [],
    },
    thstype: {
      type: String,
      default: "1",
    },
  },
  emits: ["on-change-data"],
  data() {
    return {
      waitList: [],
      localStudentList: [],
      search: "",
      searchHV: "",
      headerTable: [
        { text: "Chọn", value: "Select", width: 50, sortable: false, align: "center" },
        { text: "STT", value: "SoThuTu", sortable: false, align: "center", width: 50 },
        { text: "Học viên", value: "Student_Search", width: 150 },
        { text: "Niên khóa", value: "Nien_Khoa", width: 100, sortable: false, align: "center" },
        { text: "Tên đề tài", value: "Topic" },
      ],
      headerSelectTable: [
        { text: "STT", value: "SoThuTu", sortable: false, align: "center", width: 50 },
        { text: "Học viên", value: "Student_Search", width: 150 },
        { text: "Niên khóa", value: "Nien_Khoa", width: 150 },
        { text: "Tên đề tài", value: "Thesis_Name" },
        { text: "Xóa", value: "DelHV", width: 50, sortable: false, align: "center" },
      ],
    };
  },
  watch: {
    nganhid() {
      this.getStudentByMajor();
    },
    studentlist: {
      handler(val) {
        this.localStudentList = [...val];
      },
      immediate: true,
      deep: true,
    },
    localStudentList: {
      handler(val) {
        this.$emit("on-change-data", val);
      },
      deep: true,
    },
    nienkhoa() {
      this.getStudentByMajor();
    },
    thstype() {
      if (this.nienkhoa && this.nganhid) {
        this.getStudentByMajor();
      }
    },
  },
  mounted() {
    this.getStudentByMajor();
    this.localStudentList = [...this.studentlist];
  },
  methods: {
    resetSTT(arr) {
      return arr.map((item, index) => {
        return {
          ...item,
          Student_Search: `${item.Ho_SV || ""} ${item.Ten_SV || ""} ${item.Student_ID || ""}`,
          Topic: item.Thesis_Name || "",
          SoThuTu: index + 1,
        };
      });
    },

    async getStudentByMajor() {
      if (!this.nganhid || !this.nienkhoa) {
        this.waitList = [];
        return;
      }
      let processId = 1;
      if (this.thstype == "1") {
        if (this.nganhid == "102" || this.nganhid == "106") {
          processId = 4;
        }
      } else if (this.thstype == "2") {
        if (this.nganhid == "102" || this.nganhid == "106") {
          processId = 1;
        }
      }

      const resData = await ajaxCALLPromise("/Get_StudentWaitForThesisConfirm", {
        Process_ID: processId,
        Nganh_ID: this.nganhid,
        Nien_Khoa: this.nienkhoa,
      });

      if (resData) {
        this.waitList = resData.map((item, index) => {
          return {
            ...item,
            IsSelected: this.detailstudent.some((itemST) => itemST.Student_ID === item.Student_ID),
            Student_Search: `${item.Ho_SV || ""} ${item.Ten_SV || ""} ${item.Student_ID || ""}`,
            Topic: item.Thesis_Name || "",
            SoThuTu: index + 1,
          };
        });
      }
    },

    addAllHV() {
      this.waitList.forEach((item) => {
        if (!this.localStudentList.some((selectedItem) => selectedItem.Student_ID === item.Student_ID)) {
          this.localStudentList.push(item);
        }
      });
      this.localStudentList = this.resetSTT(this.localStudentList);
    },

    addHV(item) {
      if (!this.localStudentList.some((selectedItem) => selectedItem.Student_ID === item.Student_ID)) {
        this.localStudentList.push(item);
        this.localStudentList = this.resetSTT(this.localStudentList);
      } else {
        Vue.$toast.error("Học viên đã tồn tại", { position: "top" });
      }
    },

    deleteAll() {
      this.localStudentList = [];
    },

    removeHV(item) {
      const index = this.localStudentList.indexOf(item);
      if (index !== -1) {
        this.localStudentList.splice(index, 1);
        this.localStudentList = this.resetSTT(this.localStudentList);
      }
    },
  },
	}
</script>
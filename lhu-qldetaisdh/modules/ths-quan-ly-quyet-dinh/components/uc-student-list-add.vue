<template>
	<div>
    <v-row>
      <v-col cols="6">
        <v-card>
          <div class="d-flex align-center px-4 py-2">
            <span class="text-subtitle-1 font-weight-bold primary--text">Học viên ({{ waitList.length }})</span>
            <v-tooltip bottom>
              <template v-slot:activator="{ on, attrs }">
                <v-btn icon small color="primary" v-bind="attrs" v-on="on" @click="addAllHV" class="ml-1">
                  <v-icon size="18">mdi-playlist-plus</v-icon>
                </v-btn>
              </template>
              <span>Thêm tất cả</span>
            </v-tooltip>
            <v-spacer></v-spacer>
            <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Tìm kiếm" single-line
              hide-details dense variant="underlined" class="max-width-search-small mt-0 pt-0" />
          </div>

          <v-data-table :items="waitList" :headers="headerTable" :search="search" dense items-per-page="-1"
            :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" height="calc(100vh - 340px)" fixed-header>
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

      <v-col cols="6">
        <v-card>
          <div class="d-flex align-center px-4 py-2">
            <span class="text-subtitle-1 font-weight-bold primary--text">Đã chọn ({{ selectedList.length }})</span>
            <v-tooltip bottom>
              <template v-slot:activator="{ on, attrs }">
                <v-btn icon small color="red darken-1" v-bind="attrs" v-on="on" @click="deleteAll" class="ml-1">
                  <v-icon size="18">mdi-playlist-remove</v-icon>
                </v-btn>
              </template>
              <span>Xóa tất cả</span>
            </v-tooltip>
            <v-spacer></v-spacer>
            <v-text-field v-model="searchHV" prepend-inner-icon="mdi-magnify" placeholder="Tìm kiếm" single-line
              hide-details dense variant="underlined" class="max-width-search-small mt-0 pt-0" />
          </div>

          <v-data-table :items="selectedList" :headers="headerSelectTable" :search="searchHV" dense items-per-page="-1"
            :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" height="calc(100vh - 340px)" fixed-header>
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
            <template v-slot:item.Topic="{ item }">
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
		name: "uc-student-list-add",
  props: {
    nganhid: {
      type: [String, Number],
      default: null,
    },
    nienkhoa: {
      type: String,
      default: "",
    },
    thstype: {
      type: String,
      default: "1",
    },
    isdelete: {
      type: Boolean,
      default: false,
    },
  },
  emits: ["on-change-data"],
  data() {
    return {
      waitList: [],
      selectedList: [],
      search: "",
      searchHV: "",
      headerTable: [
        { text: "STT", value: "SoThuTu", sortable: false, align: "center", width: 50 },
        { text: "Học viên", value: "Student_Search" },
        { text: "Niên khóa", value: "Nien_Khoa", width: 100, sortable: false, align: "center" },
        { text: "Tên đề tài", value: "Topic" },
        { text: "Chọn", value: "Select", width: 50, sortable: false, align: "center" },
      ],
      headerSelectTable: [
        { text: "STT", value: "SoThuTu", sortable: false, align: "center", width: 50 },
        { text: "Học viên", value: "Student_Search", width: 150 },
        { text: "Niên khóa", value: "Nien_Khoa", width: 100, sortable: false, align: "center" },
        { text: "Tên đề tài", value: "Topic" },
        { text: "Xóa", value: "DelHV", width: 50, sortable: false, align: "center" },
      ],
    };
  },
  watch: {
    isdelete(val) {
      if (val) {
        this.selectedList = [];
      }
    },
    nienkhoa() {
      this.getStudentByMajor();
    },
    selectedList: {
      handler(val) {
        this.$emit("on-change-data", val);
      },
      deep: true,
    },
    thstype() {
      if (this.nienkhoa && this.nganhid) {
        this.getStudentByMajor();
      }
    },
    nganhid() {
      if (this.nganhid) {
        this.getStudentByMajor();
      }
    },
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
            IsSelected: true,
            Student_Search: `${item.Ho_SV || ""} ${item.Ten_SV || ""} ${item.Student_ID || ""}`,
            Topic: item.Thesis_Name || "",
            SoThuTu: index + 1,
          };
        });
      }
    },

    removeHV(item) {
      const index = this.selectedList.indexOf(item);
      if (index !== -1) {
        this.selectedList.splice(index, 1);
        this.selectedList = this.resetSTT(this.selectedList);
      }
    },

    addHV(item) {
      if (!this.selectedList.some((selectedItem) => selectedItem.Student_ID === item.Student_ID)) {
        this.selectedList.push(item);
        this.selectedList = this.resetSTT(this.selectedList);
      } else {
        Vue.$toast.error("Học viên đã tồn tại", { position: "top" });
      }
    },

    addAllHV() {
      this.waitList.forEach((item) => {
        if (!this.selectedList.some((selectedItem) => selectedItem.Student_ID === item.Student_ID)) {
          this.selectedList.push(item);
        }
      });
      this.selectedList = this.resetSTT(this.selectedList);
    },

    deleteAll() {
      this.selectedList = [];
    },
  },
	}
</script>
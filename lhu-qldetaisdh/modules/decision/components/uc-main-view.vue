<template>
	<div>
    <!-- Filter Section -->
    <v-row class="mb-1">
      <v-col cols="3">
        <v-autocomplete v-model="major" :items="nganhArr" outlined dense hide-details label="Lọc theo ngành"
          item-text="TenNganh" item-value="NganhID" />
      </v-col>
      <v-col cols="2">
        <v-autocomplete v-model="nienKhoaValue" :items="dsNienKhoa" item-text="TenNienKhoa" item-value="NienKhoa"
          outlined dense hide-details placeholder="Chọn niên khóa" label="Niên khóa" />
      </v-col>
      <v-col cols="3">
        <v-autocomplete v-model="tieuDeSelect" :items="dsTieuDe" item-text="Name" item-value="Value" outlined dense
          hide-details placeholder="Chọn tiêu đề" label="Tiêu đề" />
      </v-col>
      <v-col cols="2" class="d-flex align-center">
        <v-btn color="primary" dark class="mr-2" @click="filterQD">
          <v-icon left>mdi-filter</v-icon> Lọc
        </v-btn>
      </v-col>
      <v-col cols="2" class="d-flex justify-end align-center">
        <v-btn color="primary" class="btnAddSQDWrap" @click="$emit('on-add')">
          <v-icon left>mdi-plus</v-icon>Thêm mới
        </v-btn>
      </v-col>
    </v-row>

    <!-- Table Section -->
    <v-card class="mt-4">
      <v-card-title class="d-flex align-center py-2 px-4">
        <span class="text-subtitle-1 font-weight-bold primary--text">
          Danh sách quyết định ({{ filteredDecisionList.length }})
        </span>
        <v-spacer></v-spacer>
        <!-- Export Excel Icon Button -->
        <v-btn icon color="primary" class="mr-3" @click="exportExcel" title="Xuất Excel">
          <v-icon>mdi-microsoft-excel</v-icon>
        </v-btn>
        <!-- Search Input -->
        <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Tìm kiếm quyết định" single-line
          hide-details dense variant="underlined" class="max-width-search" />
      </v-card-title>

      <v-data-table :headers="headers" :items="filteredDecisionList" :search="search" dense :items-per-page="50"
        :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" class="elevation-1"
        height="calc(100vh - 258px)" fixed-header>
        <template v-slot:no-data>
          <c-empty-state text="Không có quyết định nào" />
        </template>
        <template v-slot:no-results>
          <c-empty-state text="Không tìm thấy quyết định phù hợp" />
        </template>
        <!-- Slot STT -->
        <template v-slot:item.stt="{ index }">
          <span>{{ index + 1 }}</span>
        </template>

        <!-- Slot File QĐ -->
        <template v-slot:item.fileQD="{ item }">
          <c-chip-file :url="item.DecisionFile_ID ? item.DecisionFile_Url : ''" label="File QĐ"
            empty-label="Chưa có file QĐ" />
        </template>

        <!-- Slot Cấp SQĐ -->
        <template v-slot:item.giveSQD="{ item }">
          <v-btn text color="success" @click="$emit('on-detail', item.Decision_ID)">
            Cấp SQĐ
          </v-btn>
        </template>

        <!-- Slot Cập nhật -->
        <template v-slot:item.editDecision="{ item }">
          <v-btn text color="info" :disabled="item.DecisionFile_ID !== null"
            @click="$emit('on-edit', item.Decision_ID)">
            Cập nhật
          </v-btn>
        </template>

        <!-- Slot In quyết định -->
        <template v-slot:item.printAction="{ item }">
          <div class="d-flex align-center justify-center">
            <v-btn icon small color="orange darken-4" @click="$emit('on-print-pdf', item)">
              <v-icon size="20">mdi-file-pdf-box</v-icon>
            </v-btn>
            <v-btn icon small color="amber darken-2" @click="$emit('on-print-word', item.Decision_ID)">
              <v-icon size="20">mdi-zip-box</v-icon>
            </v-btn>
          </div>
        </template>

        <!-- Slot Xóa -->
        <template v-slot:item.ctrl-update="{ item }">
          <v-btn icon small color="red darken-3" @click="$emit('on-delete', item)">
            <v-icon size="20">mdi-delete-outline</v-icon>
          </v-btn>
        </template>
      </v-data-table>
    </v-card>
  </div>
</template>

<script>
	export default {
		name: "uc-main-view",
  props: {
    decisionArr: {
      type: Array,
      default: () => [],
    },
    decisionFilter: {
      type: Array,
      default: () => [],
    },
    nganhArr: {
      type: Array,
      default: () => [],
    },
    dsNienKhoa: {
      type: Array,
      default: () => [],
    },
  },
  emits: ["on-add", "on-detail", "on-edit", "on-delete", "on-print-pdf", "on-print-word"],
  data() {
    return {
      search: "",
      major: "0",
      nienKhoaValue: "0",
      tieuDeSelect: "0",
      filteredDecisionList: [],
      dsTieuDe: [],
      headers: [
        { text: "STT", value: "stt", sortable: false, align: "center", width: 60 },
        { text: "Tiêu đề", value: "Decision_TieuDe", align: "start" },
        { text: "Ngành", value: "Decision_Nganh", align: "start" },
        { text: "Đợt", value: "Decision_Dot", align: "center", sortable: false },
        { text: "Niên khóa", value: "Decision_NienKhoa", align: "center" },
        { text: "Mã ngành", value: "Decision_MaSo", align: "center" },
        { text: "Số quyết định", value: "Decision_SoQD", align: "center" },
        { text: "Loại", value: "Decision_Type", align: "center" },
        { text: "Tải file QĐ", value: "fileQD", align: "center", sortable: false },
        { text: "Cấp SQĐ", value: "giveSQD", align: "center", sortable: false },
        { text: "Cập nhật", value: "editDecision", align: "center", sortable: false },
        { text: "In quyết định", value: "printAction", align: "center", sortable: false },
        { text: "Thao tác", value: "ctrl-update", align: "center", sortable: false },
      ],
    };
  },
  computed: {
    fileReadUrl() {
      return window.vueData?.v_Set?.urlReadFile || "";
    },
  },
  watch: {
    decisionFilter: {
      handler(val) {
        if (val) {
          this.filteredDecisionList = [...val];
          this.generateTieuDeOptions(val);
        }
      },
      immediate: true,
      deep: true,
    },
  },
  methods: {
    generateTieuDeOptions(list) {
      const titles = list.map((item) => item.Decision_TieuDe)
        .filter((value, index, self) => self.indexOf(value) === index);

      const options = titles.map((title) => {
        let name = "Khác";
        const lower = title.toLowerCase();

        // 1. Kiểm tra các nhóm kết hợp (Đề tài và GVHD) trước để tránh trùng lặp
        if (lower.includes("đổi tên đề tài và giảng viên hướng dẫn") || lower.includes("đổi tên đề tài và gvhd")) {
          name = "Đổi tên đề tài và GVHD";
        } else if (lower.includes("đổi tên đề tài/giảng viên hướng dẫn") || lower.includes("đổi tên đề tài/gvhd")) {
          name = "Đổi tên đề tài/GVHD";
        } else if (lower.includes("điều chỉnh tên đề tài/giảng viên hướng dẫn") || lower.includes("điều chỉnh tên đề tài/gvhd")) {
          name = "Điều chỉnh đề tài/GVHD";
        } 
        // 2. Kiểm tra các nhóm đơn lẻ
        else if (lower.includes("công nhận tên đề tài")) {
          name = "Giao đề tài";
        } else if (lower.includes("thành lập hội đồng")) {
          name = "Lập hội đồng";
        } else if (lower.includes("đổi tên đề tài")) {
          name = "Đổi đề tài";
        } else if (lower.includes("điều chỉnh tên đề tài")) {
          name = "Điều chỉnh đề tài";
        } else if (lower.includes("đổi giảng viên hướng dẫn")) {
          name = "Đổi GVHD";
        } else if (lower.includes("điều chỉnh giảng viên hướng dẫn")) {
          name = "Điều chỉnh GVHD";
        }

        return {
          Name: name,
          Value: title,
        };
      });

      this.dsTieuDe = [{ Name: "- Tất cả -", Value: "0" }, ...options];
    },

    filterQD() {
      let data = [...this.decisionArr];

      if (this.major !== "0") {
        data = data.filter((item) => item.Decision_NganhID == parseInt(this.major));
      }

      if (this.tieuDeSelect !== "0") {
        data = data.filter((item) => item.Decision_TieuDe === this.tieuDeSelect);
      }

      if (this.nienKhoaValue !== "0") {
        data = data.filter((item) => item.Decision_NienKhoa === this.nienKhoaValue);
      }

      this.filteredDecisionList = data;
    },

    exportExcel() {
      if (typeof jsonToExcel === "undefined") {
        Vue.$toast.error("Không tìm thấy hàm xuất excel toàn cục", { position: "top" });
        return;
      }
      
      const exportData = this.filteredDecisionList.map((item, index) => ({
        "STT": index + 1,
        "Tiêu đề": item.Decision_TieuDe || "",
        "Ngành": item.Decision_Nganh || "",
        "Đợt": item.Decision_Dot || "",
        "Niên khóa": item.Decision_NienKhoa || "",
        "Mã ngành": item.Decision_MaSo || "",
        "Số quyết định": item.Decision_SoQD || "",
        "Loại": item.Decision_Type || "",
      }));

      jsonToExcel({
        data: exportData,
        filename: "DanhSachQuyetDinh.xlsx",
        worksheet: "Sheet1",
      });
    },

    // A proxy method to allow legacy callback EXE: 'this.getDecision()' inside f-table or standard triggers to work
    getDecision() {
      this.$emit("on-reload");
    },
  },
	}
</script>
<template>
	<div class="fill-height d-flex flex-column overflow-hidden">
    <v-card class="fill-height d-flex flex-column overflow-hidden">
      <v-card-title class="primary--text mb-0 pb-0 py-2 d-flex align-center flex-grow-0 flex-shrink-0">
        <span class="text-subtitle-1 font-weight-bold">Danh sách học viên ({{ studentArr.length }})</span>
        <v-spacer></v-spacer>
        <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Tìm kiếm" single-line hide-details dense
          variant="underlined" class="max-width-search-small" />
      </v-card-title>

      <v-data-table :items="studentArr" :headers="headerTable" :search="search" item-key="Student_ID" dense
        :items-per-page="-1" height="calc(90vh - 380px)" fixed-header hide-default-footer class="flex-grow-1">
        <template v-slot:no-data>
          <c-empty-state text="Không có học viên nào" />
        </template>
        <template v-slot:no-results>
          <c-empty-state text="Không tìm thấy học viên phù hợp" />
        </template>
        <template v-slot:item.STT="{ index }">
          {{ index + 1 }}
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
          <span v-if="item.Thesises_Prof2 === '' || item.Thesises_Prof2 === null">
            GVHD: {{ item.Thesises_Prof1 }}
          </span>
          <span v-else>
            GVHD 1: {{ item.Thesises_Prof1 }} <br />
            GVHD 2: {{ item.Thesises_Prof2 }}
          </span>
        </template>
      </v-data-table>
    </v-card>
  </div>
</template>

<script>
	export default {
		name: "uc-student-detail-table",
  props: {
    studentlist: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      search: "",
      headerTable: [
        { text: "STT", value: "STT", sortable: false, align: "center", width: 50 },
        { text: "Học viên", value: "Student_Search", width: 200 },
        { text: "Niên khóa", value: "Nien_Khoa", width: 100, sortable: false, align: "center" },
        { text: "Tên ngành", value: "Ten_Nganh" },
        { text: "Tên đề tài", value: "Topic" },
      ],
    };
  },
  computed: {
    studentArr() {
      return this.studentlist.map((item, index) => {
        return {
          ...item,
          stt: index + 1,
          Student_Search: `${item.Ho_SV || ""} ${item.Ten_SV || ""} ${item.Student_ID || ""}`,
          Topic: item.Thesis_Name || "",
        };
      });
    },
  },
	}
</script>
<template>
    <div>
        <v-card>
            <v-card-title class="primary--text mb-0 pb-0">
                Danh sách học viên ({{ studentArr.length }})
                <v-spacer></v-spacer>
                <v-text-field class="mb-5" v-model="search" append-icon="mdi-magnify" label="Search" single-line hide-details />
            </v-card-title>

            <v-data-table :items="studentArr" :headers="headerTable" :search="search" dense items-per-page="-1" :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
                <template v-slot:item.STT="{ item, index }">
                    {{ index + 1 }}
                </template>
                <template v-slot:item.Student_ID="{ item }">
                    <span class="primary--text">
                        <b> {{ item.Ho_SV }} {{ item.Ten_SV }}</b>
                    </span>
                    <br />
                    <b>{{ item.Student_ID }}</b>
                    <span class="amber--text"> [{{ item.Lop_ID }}]</span>
                </template>
                <template v-slot:item.Topic="{ item }">
                    <b>{{ item.Thesis_Name }}</b> <br />
                    <span v-if="item.Thesises_Prof2 === '' || item.Thesises_Prof2 === null"> GVHD: {{ item.Thesises_Prof1 }} </span>
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
    props: ['studentlist'],
    data() {
        return {
            search: '',

            headerTable: [
                {
                    text: 'STT',
                    value: 'STT',
                    sortable: false,
                    align: 'center',
                    width: 50,
                },
                {
                    text: 'Học viên',
                    value: 'Student_ID',
                    width: 200,
                },
                {
                    text: 'Niên khóa',
                    value: 'Nien_Khoa',
                    width: 100,
					sortable: false,
                    align: 'center',
                },
				{
                    text: 'Tên ngành',
                    value: 'Ten_Nganh',
                },
                {
                    text: 'Tên đề tài',
                    value: 'Topic',
                },
            ],
        }
    },
    computed: {
        studentArr: function () {
            return this.studentlist.map((item, index) => {
                return {
                    ...item,
                    stt: index + 1,
                }
            })
        },
    },
    watch: {},
    methods: {},
}
</script>

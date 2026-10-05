<template>
	<div>
        <div class="mb-3 d-flex justify-end">
            <v-btn @click="isAddModalOpen = true" color="success">
                <v-icon left>mdi-plus</v-icon> Định nghĩa lớp mới
            </v-btn>
        </div>

        <c-table :is-new="false" :is-edit="false" is-search dense fixed-header height="calc(100vh - 185px)"
        hide-default-footer
            :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" :items-per-page="-1" :headers="tableHeader"
            :items="ClassList" :label="labelTable">
            <template v-slot:item.Process_ID="{ item }">
                <v-chip v-if="item.Process_ID === 1" color="primary" dark>Thạc sĩ nghiên cứu</v-chip>
                <v-chip v-else-if="item.Process_ID === 2" color="warning" dark>Đổi đề tài</v-chip>
                <v-chip v-else-if="item.Process_ID === 3" color="indigo" dark>Gia hạn đề tài</v-chip>
                <v-chip v-else-if="item.Process_ID === 4" color="pink" dark>Thạc sĩ ứng dụng</v-chip>
                <v-chip v-else-if="item.Process_ID === 5" color="teal" dark>Đổi đề tài ứng dụng</v-chip>
                <v-chip v-else-if="item.Process_ID === 6" color="purple" dark>Tiến sĩ</v-chip>
            </template>
            <template v-slot:item.Process_Action="{ item }">
                <p class="mb-0" v-if="item.Process_Action === 1">Làm luận văn</p>
                <p class="mb-0" v-else-if="item.Process_Action === 2">Đổi đề tài</p>
                <p class="mb-0" v-else-if="item.Process_Action === 3">Gia hạn đề tài</p>
                <p class="mb-0" v-else-if="item.Process_Action === 4">Làm luận án</p>
            </template>
            <template v-slot:item.ProcessClassStatus="{ item }">
                <p class="mb-0" v-if="item.ProcessClassStatus === 0">
                    <v-icon left color="success">mdi-check</v-icon> Đang hoạt động
                </p>
                <p class="mb-0" v-else-if="item.ProcessClassStatus === 1">
                    <v-icon left color="error">mdi-close</v-icon> Đã bị hủy
                </p>
            </template>
        </c-table>

        <uc-modal-add v-model="isAddModalOpen" @on-reload="onLoadClassProcess" />
    </div>
</template>

<script>
	export default {
		name: "uc-main-page",
    props: [],
    data() {
        return {
            isAddModalOpen: false,
            ClassList: [],
            labelTable: "Danh sách lớp",
            tableHeader: [
                {
                    text: "STT",
                    value: "STT",
                    sortable: false,
                    align: "center",
                    width: 20,
                },
                {
                    text: "Lớp",
                    value: "Lop_ID",
                    sortable: false,
                    width: 50,
                },
                {
                    text: "Loại thạc sĩ",
                    value: "Process_ID",
                    sortable: false,
                    width: 20,
                },
                {
                    text: "Loại thao tác",
                    value: "Process_Action",
                    sortable: false,
                    width: 50,
                },
                {
                    text: "Trạng thái",
                    value: "ProcessClassStatus",
                    sortable: false,
                    align: "center",
                    width: 50,
                },
            ],
        };
    },
    mounted() {
        this.onLoadClassProcess();
    },
    methods: {
        async onLoadClassProcess() {
            const data = await ajaxCALLPromise("/Process_Class_Get", null);
            const PHD_PROCESS_IDS = [6, 7, 8];
            this.ClassList = (data || [])
                .filter((item) => !PHD_PROCESS_IDS.includes(item.Process_ID))
                .map((item, index) => {
                    return {
                        ...item,
                        STT: index + 1,
                    };
                });
            this.labelTable = `Danh sách lớp (${this.ClassList.length})`;
        },
    },
	}
</script>
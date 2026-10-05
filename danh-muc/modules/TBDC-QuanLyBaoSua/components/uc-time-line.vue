<template>
    <v-timeline truncate-line="both" class="my-1" style="font-size: 10px" size="x-small" side="end"
        direction="horizontal">
        <v-timeline-item icon="mdi-send-circle" icon-color="white" dot-color="warning">
            <template v-slot:opposite>Báo sửa</template>
            <div class="text-center">
                <div class="text-caption text-no-wrap">{{ getShortName(item.HoTenNguoiBaoSua) }}
                </div>
                <p>
                    {{ splitDateTime(item.ThoiGianBaoSua).time }} <br />
                    {{ splitDateTime(item.ThoiGianBaoSua).date }}
                </p>

            </div>
        </v-timeline-item>

        <v-timeline-item v-if="item.TinhTrangXuLy.TiepNhan" icon-color="white" icon="mdi-tag"
            dot-color="teal-lighten-3">
            <template v-slot:opposite> Tiếp nhận </template>
            <div class="text-center">
                <div class="text-caption text-no-wrap">
                    {{ getShortName(item.TinhTrangXuLy?.TiepNhan.TenNhanVienXuLy) }}</div>
                <p class="pa-0">
                    {{ splitDateTime(item.TinhTrangXuLy?.TiepNhan.ThoiGianXuLy).time }} <br />
                    {{ splitDateTime(item.TinhTrangXuLy?.TiepNhan.ThoiGianXuLy).date }}
                </p>
            </div>
        </v-timeline-item>

        <v-timeline-item v-if="item.TinhTrangXuLy?.KiemTra" icon-color="white" icon="mdi-clipboard-search"
            dot-color="teal-lighten-3">
            <template v-slot:opposite> Kiểm tra </template>
            <div class="text-center">
                <div class="text-caption text-no-wrap">
                    {{ getShortName(item.TinhTrangXuLy?.KiemTra.TenNhanVienXuLy) }}</div>
                <p>
                    {{ splitDateTime(item.TinhTrangXuLy?.KiemTra.ThoiGianXuLy).time }} <br />
                    {{ splitDateTime(item.TinhTrangXuLy?.KiemTra.ThoiGianXuLy).date }}
                </p>
            </div>
        </v-timeline-item>
        <v-timeline-item v-if="item.TinhTrangXuLy?.DangSua" icon-color="white" icon="mdi-cog" dot-color="teal-lighten-3">
            <template v-slot:opposite> Đang sửa </template>
            <div class="text-center">
                <div class="text-caption text-no-wrap">
                    {{ getShortName(item.TinhTrangXuLy?.DangSua.TenNhanVienXuLy) }}</div>
                <p>
                    {{ splitDateTime(item.TinhTrangXuLy?.DangSua.ThoiGianXuLy).time }} <br />
                    {{ splitDateTime(item.TinhTrangXuLy?.DangSua.ThoiGianXuLy).date }}
                </p>
            </div>
        </v-timeline-item>

        <v-timeline-item v-if="item.TinhTrangXuLy?.DaXong" icon="mdi-check" dot-color="success">
            <template v-slot:opposite> Sửa xong </template>
            <div class="text-center">
                <div class="text-caption text-no-wrap">
                    {{ getShortName(item.TinhTrangXuLy?.DaXong.TenNhanVienXuLy) }}</div>
                <p>
                    {{ splitDateTime(item.TinhTrangXuLy?.DaXong.ThoiGianXuLy).time }} <br />
                    {{ splitDateTime(item.TinhTrangXuLy?.DaXong.ThoiGianXuLy).date }}
                </p>
            </div>
        </v-timeline-item>
        <v-timeline-item v-if="item.TinhTrangXuLy?.BaoSai" icon="mdi-cancel" icon-color="white" dot-color="error">
            <template v-slot:opposite> Báo sai </template>
            <div class="text-center">
                <div class="text-caption text-no-wrap">
                    {{ getShortName(item.TinhTrangXuLy?.BaoSai.TenNhanVienXuLy) }}</div>
                <p>
                    {{ splitDateTime(item.TinhTrangXuLy?.BaoSai.ThoiGianXuLy).time }} <br />
                    {{ splitDateTime(item.TinhTrangXuLy?.BaoSai.ThoiGianXuLy).date }}
                </p>
            </div>
        </v-timeline-item>

        <v-timeline-item v-if="item.TinhTrangXuLy?.Hu" dot-color="error" icon="mdi-close-octagon-outline"
            icon-color="white">
            <template v-slot:opposite> Tài sản hư </template>
            <div class="text-center">
                <div class="text-caption text-no-wrap">{{
                    getShortName(item.TinhTrangXuLy?.Hu.TenNhanVienXuLy)
                    }}
                </div>
                <p>
                    {{ splitDateTime(item.TinhTrangXuLy?.Hu.ThoiGianXuLy).time }} <br />
                    {{ splitDateTime(item.TinhTrangXuLy?.Hu.ThoiGianXuLy).date }}
                </p>
            </div>
        </v-timeline-item>
    </v-timeline>
</template>

<script>
export default {

    props: {
        item: Object,
    },

    data() {
        return {
        }
    },

    mounted() {
    },
    computed: {
    },

    watch: {
    },

    methods: {
        getShortName(fullName, wordCount = 1) {
            if (!fullName) return "";

            const words = fullName.trim().split(/\s+/);
            return words.slice(-wordCount).join(" ");
        },

        splitDateTime(dateTimeStr) {
            const [time, date] = dateTimeStr.trim().split(" - ");
            return { date, time };
        },
    }

}
</script>

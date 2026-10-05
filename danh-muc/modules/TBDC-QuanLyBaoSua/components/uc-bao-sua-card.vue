<template>
    <v-card class="py-1 mb-1" style="border-radius:12px;border-width:0.1px;box-shadow:rgba(0,0,0,0.1) 0px 1px 1px;">
        <v-card-title class="text-caption">
            <v-row>
                <v-col cols="3" class="text-grey-lighten-1">
                    ID: {{ BaoSua_Id }}
                </v-col>

                <v-col cols="9" class="d-flex justify-end">
                    <v-chip size="x-small" :color="mapDoUuTien[DoUuTien]?.color" tonal>
                        {{ mapDoUuTien[DoUuTien]?.text }}
                    </v-chip>
                </v-col>
            </v-row>
        </v-card-title>

        <v-card-text class="text-subtitle-2 text-grey-darken-1 pb-0">
            <v-row>
                <v-col cols="2" style="max-width:30px">
                    <uc-avatar :AnhDaiDien_Url="AnhDaiDien_Url" :Ten="HoTenNguoiBaoSua"></uc-avatar>
                </v-col>

                <v-col>
                    <div class="text-grey-darken-1" style="font-size:14px;margin-top:-5px">
                        <span class="text-caption">{{ HoTenNguoiBaoSua }}</span>
                    </div>

                    <div class="text-grey-darken-1" style="font-size:11px;margin-top:-3px">
                        {{ ThoiGianBaoSua }}
                    </div>
                </v-col>
            </v-row>

            <div class="mt-2">
                {{ GhiChu }}
            </div>
        </v-card-text>

        <v-card-title class="text-caption">
            <v-row>
                <v-col cols="5" class="d-flex align-center text-grey-darken-1">
                    <v-icon size="small" color="grey">mdi-map-marker-radius-outline</v-icon>
                    <span style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">
                        {{ TenDiaDiem }}
                    </span>
                </v-col>
                <v-col cols="7" class="d-flex justify-end">
                    <span class="text-caption" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">
                        {{ TenHangHoa }}
                    </span>
                </v-col>
            </v-row>
        </v-card-title>

    </v-card>
</template>

<script>
export default {
    props: [
        "BaoSua_Id",
        "TenDiaDiem",
        "GhiChu",
        "DoUuTien",
        "ThoiGianBaoSua",
        "HoTenNguoiBaoSua",
        "TenHangHoa",
        "AnhDaiDien_Url",
    ],
    data() {
        return {
            mapDoUuTien,
        }
    },
    methods: {
        formatDateTime: window.formatDateTime,
    }
}
</script>
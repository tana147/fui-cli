<template>
    <v-row>
        <v-col cols="12" class="pb-0 success--text subtitle-1">
            <b>{{ CTSanPham_CuaHang.TenCuaHang }}</b>
        </v-col>
        <v-col cols="12" class="pt-1">
            <v-row>
                <v-col>
                    <v-text-field type="number" v-model="CTSanPham_CuaHang.GiaBan_CuaHang" dense
                        label="Giá bán (Tại cửa hàng)" outlined hide-details></v-text-field>
                </v-col>
                <v-col>
                    <v-text-field type="number" v-model="CTSanPham_CuaHang.VAT_CuaHang" dense
                        label="% Thuế VAT (Tại cửa hàng)" outlined hide-details></v-text-field>
                </v-col>
                <v-col>
                    <v-text-field type="number" v-model="CTSanPham_CuaHang.GiaBan_App" dense label="Giá bán (Trên App)"
                        outlined hide-details></v-text-field>
                </v-col>
                <v-col>
                    <v-text-field type="number" v-model="CTSanPham_CuaHang.VAT_App" dense label="% Thuế VAT (Trên App)"
                        outlined hide-details></v-text-field>
                </v-col>
                <v-col>
                    <v-btn color="success" v-on:click="onSave()" elevation="0"><v-icon
                            left>mdi-content-save</v-icon>Lưu</v-btn>
                </v-col>
            </v-row>
        </v-col>
    </v-row>
</template>
<script>
export default {
    props: ["sp_ch"],
    computed: {
        CTSanPham_CuaHang: function () {
            return this.sp_ch ?? {}
        },
    },
    methods: {
        onSave() {
            const formData = this.CTSanPham_CuaHang
            const merchantID = vueData.DS_SanPham_CuaHang.find(x => x.SanPham_CuaHangID == formData.SanPham_CuaHangID).MerchantID

            if (merchantID == null || !formData.GiaBan_App || !formData.ChoPhepBan_App) // nếu ko có merchantID thì lưu ở hệ thống eorder
                return this.callSaveEorder(formData)

            confirm({
                title: "Thao tác này sẽ ảnh hướng tới món trên GRAB?",
                action: async () => {
                    const infoSync = await this.getTimeLastSync(merchantID);

                    if (!infoSync.canSync) {
                        showToast({
                            type: "warning",
                            title: `Vui lòng đợi ${infoSync.waitSeconds}s để đồng bộ lại với GRAB, cập nhật gần nhất: ${infoSync.lastSyncTime}`,
                        });
                        return;
                    }
                    const isItemUpdateSuccess = await this.callSaveItemGrab(merchantID, formData)
                    const isModifierUpdateSuccess = await this.callSaveModifierGrab(merchantID, formData)

                    if ((isItemUpdateSuccess || isModifierUpdateSuccess) ||(!isItemUpdateSuccess && !isModifierUpdateSuccess))
                        return this.callSaveEorder(formData)
                }
            })

        },
        async getTimeLastSync(merchantID) {
            return new Promise((resolve) => {
                ajaxCALL(
                    "/eorder/Grab_Get_TimeLastSync",
                    { merchantID: merchantID },
                    (res) => {
                        const data = res?.data?.[0] || {};

                        resolve({
                            lastSyncTime: data.LastSyncTime || null,
                            canSync: data.CanSync,     
                            waitSeconds: data.WaitSeconds || 0,
                        });
                    },
                );
            });
        },
        callSaveEorder(formData) {

            const params = {
                SanPham_CuaHangID: formData.SanPham_CuaHangID,
                GiaBan_CuaHang: formData.GiaBan_CuaHang,
                GiaBan_App: formData.GiaBan_App,
                VAT_CuaHang: formData.VAT_CuaHang,
                VAT_App: formData.VAT_App,
            }
            ajaxCALL("/eorder/SanPham_Update_Gia", params, () => {
                showToast({ type: "green", title: "Lưu thiết lập giá thành công" })
            })
        },
        callSaveItemGrab(merchantID, formData) {
            return new Promise((resolve) => {
                const paramsItem = {
                    price: Number(formData.GiaBan_App),
                    field: "ITEM",
                    id: formData.SanPhamID.toString(),
                    merchantID: merchantID
                }

                ajaxCALL("/eorder/GRABPUSH_Menu_Update", {
                    Json_Data: JSON.stringify(paramsItem)
                },
                    async (response) => {
                        if (response.httpErrorCode == 409) {
                            showToast({ type: "red", title: 'GRAB ERROR: ' + response.responseData?.message });
                            return resolve(false);
                        }
                        else if (response.responseData) {
                            return resolve(false);
                        }
                        return resolve(true);
                    })
            })
        },
        callSaveModifierGrab(merchantID, formData) {
            return new Promise((resolve) => {
                const paramsModifier = {
                    price: Number(formData.GiaBan_App),
                    field: "MODIFIER",
                    id: formData.SanPhamID.toString(),
                    name: vueData.CTSanPham["SanPham"].TenSanPham,
                    merchantID: merchantID
                }

                ajaxCALL("/eorder/GRABPUSH_Menu_Update", {
                    Json_Data: JSON.stringify(paramsModifier)
                }, (response) => {
                    if (response.httpErrorCode == 409) {
                        showToast({ type: "red", title: 'GRAB ERROR: ' + response.responseData?.message });
                        return resolve(false);
                    }
                    else if (response.responseData) {
                        return resolve(false);
                    }
                    return resolve(true);
                })
            })
        }

    },
}
</script>

<template>
	<div>
        <v-edit-dialog return-value.sync="value" cancel-text="Đóng" save-text="Lưu" large @save="save">
            <span :class="renderClassSoLuongTon" class="text-center d-flex" style="gap: 5px">
                {{ item.SoLuongTon.toLocaleString("vi-vn") }}
                <v-icon small color="primary">mdi-pencil</v-icon>
            </span>
            <template v-slot:input>
                <p class="text-subtitle-1 font-weight-medium mt-2 text-primary mb-0">Cập nhật số lượng tồn</p>
                <v-text-field v-model="item.SoLuongTon" single-line />
            </template>
        </v-edit-dialog>
    </div>
</template>

<script>
	export default {
		props: ["value"],
    computed: {
        item: function () {
            return Object.assign({}, this.value)
        },
        renderClassSoLuongTon: function () {
            return this.item.SoLuongTon > 0 ? "" : "error--text cursor-pointer"
        },
    },
    methods: {
        save() {
            const MerchantID = vueData.DSCuaHang?.find(ch => ch.CuaHangID == vueData.CuaHangID).MerchantID
            if (!MerchantID || !this.item.ChoPhepBan_App) return this.callSaveEorder()

            confirm({
                title: "Thao tác này sẽ ảnh hưởng tới món trên GRAB?",
                action: async () => {
                    const syncInfo = await this.getTimeLastSync(MerchantID);

                    if (!syncInfo.canSync) {
                        showToast({
                            type: "warning",
                            title: `Vui lòng đợi ${syncInfo.waitSeconds}s để đồng bộ lại với GRAB, cập nhật gần nhất: ${syncInfo.lastSyncTime}.`,
                        });
                        return;
                    }

                    const isItemUpdateSuccess = await this.callSaveItemGrab(MerchantID)
                    const isModifierUpdateSuccess = await this.callSaveModifierGrab(MerchantID)

                    if ((isItemUpdateSuccess || isModifierUpdateSuccess)) return this.callSaveEorder()
                }
            })
        },
        callSaveEorder() {
            const $this = this
            const params = { SanPham_CuaHangID: $this.item.SanPham_CuaHangID, SoLuongTon: parseFloat($this.item.SoLuongTon ?? 0) }
            ajaxCALL("/eorder/SanPham_Update_SoLuongTon", params, (res) => {
                Vue.$toast.success("Cập nhật số lượng tồn thành công", { position: "top" })
                runAction(vueData.getSanPham)
            })
        },
        callSaveItemGrab(merchantID) {
            return new Promise((resolve) => {
                const paramsSaveGrab = {
                    merchantID: merchantID,
                    id: this.item.SanPhamID.toString(),
                    field: 'ITEM',
                    availableStatus: Number(this.item.SoLuongTon) > 0 ? 'AVAILABLE' : 'UNAVAILABLE',
                    maxStock: Number(this.item.SoLuongTon),
                }
                ajaxCALL("/eorder/GRABPUSH_Menu_Update", {
                    Json_Data: JSON.stringify(paramsSaveGrab)
                },
                    async (response) => {
                        if (response.httpErrorCode == 409) {
                            showToast({ type: "red", title: 'GRAB ERROR:' + response.responseData?.message });
                            return resolve(false);
                        }
                        else if (response.responseData) {
                            return resolve(false);
                        }
                        return resolve(true);
                    })
            })
        },
        callSaveModifierGrab(merchantID) {
            return new Promise((resolve) => {
                const paramsSaveGrabModifier = {
                    merchantID: merchantID,
                    id: this.item.SanPhamID.toString(),
                    field: 'MODIFIER',
                    name: this.item.TenSanPham,
                    availableStatus: Number(this.item.SoLuongTon) > 0 ? 'AVAILABLE' : 'UNAVAILABLE',
                    maxStock: Number(this.item.SoLuongTon),
                }

                ajaxCALL("/eorder/GRABPUSH_Menu_Update", {
                    Json_Data: JSON.stringify(paramsSaveGrabModifier)
                },
                    async (response) => {
                        if (response.httpErrorCode == 409) {
                            showToast({ type: "red", title: 'GRAB ERROR:' + response.responseData?.message });
                            return resolve(false);
                        }
                        else if (response.responseData) {
                            return resolve(false);
                        }
                        return resolve(true);
                    })
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
                            canSync: data.CanSync,      // ← Dùng giá trị từ backend
                            waitSeconds: data.WaitSeconds || 0,
                        });
                    },
                );
            });
        }

    },
	}
</script>
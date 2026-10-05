<template>
	<v-row>
		<v-col cols="12" class="pb-0 success--text subtitle-1">
			<b>{{ CTSanPham_CuaHang.TenCuaHang }}</b>
		</v-col>
		<v-col cols="12" class="pt-1">
			<v-row>
				<v-col md="2">
					<v-select v-model="CTSanPham_CuaHang.TinhTrang" dense label="Trạng thái món" :items="DSTinhTrang"
						hide-details outlined></v-select>
				</v-col>
				<v-col>
					<v-checkbox class="mt-1" v-model="CTSanPham_CuaHang.ChoPhepBan" label="Bán trực tiếp (POS, mPOS)"
						color="success" hide-details></v-checkbox>
				</v-col>
				<v-col>
					<v-checkbox class="mt-1" v-model="CTSanPham_CuaHang.ChoPhepBan_App" label="Bán trên App (Grab)"
						color="success" hide-details></v-checkbox>
				</v-col>
				<v-col>
					<v-checkbox class="mt-1" v-model="CTSanPham_CuaHang.ChoPhepBan_OrderTaiBan" label="Order tại bàn "
						color="success" hide-details></v-checkbox>
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
	data: () => {
		return {
			DSTinhTrang: [
				{
					text: "Đang bán",
					value: 0,
				},
				{
					text: "Tạm hết",
					value: 1,
				},
			],
		}
	},
	computed: {
		CTSanPham_CuaHang: function () {
			return this.sp_ch ?? {}
		},
	},
	methods: {
		onSave() {
			const $this = this
			const CTSanPham_CuaHang = $this.CTSanPham_CuaHang
			const merchantID = vueData.DS_SanPham_CuaHang.find(x => x.SanPham_CuaHangID == CTSanPham_CuaHang.SanPham_CuaHangID).MerchantID


			if (merchantID === null)
				return this.callSaveEorder(CTSanPham_CuaHang)
			confirm({
				title: "Thao tác này sẽ ảnh hưởng tới món trên GRAB?",
				action: async () => {
					const infoSync = await this.getTimeLastSync(merchantID);
					if(infoSync.canSync === false) {
						showToast({
							type: "warning",
							title: `Vui lòng đợi ${infoSync.waitSeconds}s để đồng bộ lại với GRAB, cập nhật gần nhất: ${infoSync.lastSyncTime}`,
						});
						return;
					}

					const isItemUpdateSuccess = await this.callSaveItemGrab(merchantID, CTSanPham_CuaHang)
					const isModifierUpdateSuccess = await this.callSaveModifierGrab(merchantID, CTSanPham_CuaHang)

					if ((isItemUpdateSuccess || isModifierUpdateSuccess) ||(!isItemUpdateSuccess && !isModifierUpdateSuccess))
						return this.callSaveEorder(CTSanPham_CuaHang)
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
			const $this = this
			const params = {
				SanPham_CuaHangID: formData.SanPham_CuaHangID,
				TinhTrang: formData.TinhTrang,
				ChoPhepBan: formData.ChoPhepBan ?? 0,
				ChoPhepBan_App: formData.ChoPhepBan_App ?? 0,
				ChoPhepBan_OrderTaiBan: formData.ChoPhepBan_OrderTaiBan ?? 0
			}
			ajaxCALL("/eorder/SanPham_Update_TrangThai", params, (res) => {
				showToast({ type: "green", title: "Lưu trạng thái thành công" })
				//Gửi Socket sang màn hình Menu POS
				const webSocketHubMenu = `menu_pos_${$this.sp_ch.CuaHangID}`
				vueData.webSocket = { [webSocketHubMenu]: null }
				webSocket_Send({ group: webSocketHubMenu, data: Date.now() })
			})
		},
		callSaveItemGrab(merchantID, formData) {
			return new Promise((resolve) => {
				const paramsItem = {
					availableStatus: formData.TinhTrang == 0 ? 'UNAVAILABLE' : 'AVAILABLE',
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
		callSaveModifierGrab(merchantID, itemDetail) {
			// gọi lấy danh sách loại nhóm loại ly để cập nhật trạng thái ly trên grab
			ajaxCALL("/eorder/NhomLoaiLyDiem_Select_BySanPhamID", { SanPhamID: itemDetail.SanPhamID }, (response) => {
				if (!Array.isArray(response.data) || response.data.length === 0) {
					return new Promise((resolve) => {
						const paramsModifier = {
							availableStatus: itemDetail.TinhTrang == 0 ? 'AVAILABLE' : 'UNAVAILABLE',
							field: "MODIFIER",
							name: vueData.CTSanPham["SanPham"].TenSanPham,
							id: itemDetail.SanPhamID.toString(),
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

				const modifiers = response.data
				const results = []
				modifiers.forEach(element => {
					const paramsModifierGrab = {
						availableStatus: itemDetail.TinhTrang == 0 ? 'AVAILABLE0' : 'UNAVAILABLE',
						field: "MODIFIER",
						name: vueData.CTSanPham["SanPham"].TenSanPham,
						merchantID: merchantID,
						id: `CUP_${element.NhomLoaiLyDiemID}` // Định dạng id modifier trên grab là CUP_{NhomLoaiLyDiemID}
					}
					ajaxCALL("/eorder/GRABPUSH_menu_Update", { Json_Data: JSON.stringify(paramsModifierGrab) }, (response) => {
						if (response.httpErrorCode == 409) {
							showToast({ type: "red", title: "GRAB ERROR: " + response.responseData?.message })
							results.push(false)
						} else if (response.responseData) {
							results.push(false)
						}
						results.push(true)
					})
				});

				return results.every(r => r === true)
			})
		},
	},
}
</script>
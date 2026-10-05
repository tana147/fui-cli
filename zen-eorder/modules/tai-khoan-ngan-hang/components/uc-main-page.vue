<template>
	<div>
		<v-tabs v-model="TabModel" color="white" background-color="green">
			<v-tab key="Tab_BankAccount">Tài khoản ngân hàng</v-tab>
			<v-tab key="Tab_SetUpDiscounts">Thiết lập chiết khấu</v-tab>
		</v-tabs>
		<v-tabs-items v-model="TabModel">
			<v-tab-item key="Tab_BankAccount">
				<uc-tab-bank-account />
			</v-tab-item>
			<v-tab-item key="Tab_SetUpDiscounts">
				<uc-tab-set-up-discounts ref="SetUpDiscounts" />
			</v-tab-item>
		</v-tabs-items>
	</div>
</template>

<script>
	export default {
		data() {
			return {
				TabModel: 0
			}
		},
		watch: {
			TabModel(newVal) {
				if (newVal === 2) {
					runAction(vueData.getNganHang);
				}
			},
		}
	}
</script>
<template>
    <v-dialog v-model="vueData.isOpenDialogCTHoaDon" width="800">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>Thiết lập thông tin hóa đơn điện tử - {{ vueData.rowSelectedObject.TenCuaHang
                }}</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.isOpenDialogCTHoaDon = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <v-form ref="formRef" lazy-validation>
                    <v-row>
                        <v-col cols="6">
                            <v-text-field label="Ký hiệu mẫu hóa đơn"
                                v-model="vueData.rowSelectedObject.Invoice_TemplateCode" outlined dense
                                hide-details="auto" maxlength="20" :rules="[rules.required]"></v-text-field>
                        </v-col>
                        <v-col cols="6">
                            <v-text-field label="Ký hiệu hóa đơn"
                                v-model="vueData.rowSelectedObject.Invoice_InvoiceSeries" outlined dense
                                hide-details="auto" maxlength="25"
                                :rules="[rules.required, rules.invoiceSeries]"></v-text-field>
                        </v-col>
                        <v-col cols="4">
                            <v-text-field label="Mã loại hóa đơn"
                                v-model="vueData.rowSelectedObject.Invoice_InvoiceType" outlined dense
                                hide-details="auto"> </v-text-field>
                        </v-col>
                        <v-col cols="2">
                            <v-select label="Mã tiền tệ" v-model="vueData.rowSelectedObject.Invoice_CurrencyCode"
                                :items="DSMaTienTe" outlined dense hide-details="auto"
                                :rules="[rules.required]"></v-select>
                        </v-col>
                        <v-col cols="6">
                            <v-text-field label="MST của doanh nghiệp"
                                v-model="vueData.rowSelectedObject.Invoice_SellerTaxCode" outlined dense
                                hide-details="auto" maxlength="20" :rules="[rules.required]"></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-text-field label="Tên doanh nghiệp"
                                v-model="vueData.rowSelectedObject.Invoice_SellerLegalName" outlined dense
                                hide-details="auto" :rules="[rules.required]"></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-textarea label="Địa chỉ" v-model="vueData.rowSelectedObject.Invoice_SellerAddressLine"
                                outlined dense hide-details="auto" :rows="2" :rules="[rules.required]"></v-textarea>
                        </v-col>
                        <v-col cols="12">
                            <v-textarea label="Địa chỉ mặc định (Dành cho khách không xuất hóa đơn)"
                                v-model="vueData.rowSelectedObject.Invoice_CusAddessDefault" outlined dense
                                hide-details="auto" :rows="1"></v-textarea>
                        </v-col>
                        <v-col cols="4">
                            <v-text-field label="SĐT doanh nghiệp"
                                v-model="vueData.rowSelectedObject.Invoice_SellerPhoneNumber" outlined dense
                                hide-details="auto" maxlength="20" :rules="[rules.required]"></v-text-field>
                        </v-col>
                        <v-col cols="4">
                            <v-text-field label="Số fax" v-model="vueData.rowSelectedObject.Invoice_SellerFaxNumber"
                                outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="4">
                            <v-text-field label="Email doanh nghiệp"
                                v-model="vueData.rowSelectedObject.Invoice_SellerEmail" outlined dense
                                hide-details="auto" :rules="[rules.required]"></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-checkbox label="Cho phép khách hàng tra cứu hóa đơn"
                                v-model="vueData.rowSelectedObject.Invoice_CusGetInvoiceRight" dense
                                hide-details="auto" />
                        </v-col>
                    </v-row>
                </v-form>
            </v-card-text>
            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="primary" @click="UpdateInvoice()" text>Lưu</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: [],
    data() {
        return {
            vueData,
            DSMaTienTe: [{ text: "VND", value: "VND" }],
            rules: {
                required: (value) => !!value || "Bắt buộc.",
                invoiceSeries: (value) => {
                    const regex = /^[a-zA-Z0-9/]*$/ // Chỉ cho phép chữ hoa và số, tối đa 20 ký tự
                    return regex.test(value) || "Ký hiệu hóa đơn không hợp lệ."
                },
            },
        }
    },
    mounted() {
    },
    computed: {},
    watch: {
        "vueData.isOpenDialogCTHoaDon": function (val) {
            if (val) {
                this.$refs.formRef?.resetValidation() // chỉ reset nếu form đã được render
            }
        },
    },
    methods: {
        async UpdateInvoice() {
            const $this = this
            let valid = await this.$refs.formRef.validate()
            if (!valid) return
            const params = {
                CuaHangID: vueData.CuaHangID,
                Invoice_InvoiceType: vueData.rowSelectedObject.Invoice_InvoiceType,
                Invoice_TemplateCode: vueData.rowSelectedObject.Invoice_TemplateCode,
                Invoice_InvoiceSeries: vueData.rowSelectedObject.Invoice_InvoiceSeries,
                Invoice_CurrencyCode: vueData.rowSelectedObject.Invoice_CurrencyCode,
                Invoice_CusGetInvoiceRight: vueData.rowSelectedObject.Invoice_CusGetInvoiceRight,
                Invoice_CusAddessDefault: vueData.rowSelectedObject.Invoice_CusAddessDefault,
                Invoice_SellerTaxCode: vueData.rowSelectedObject.Invoice_SellerTaxCode,
                Invoice_SellerLegalName: vueData.rowSelectedObject.Invoice_SellerLegalName,
                Invoice_SellerAddressLine: vueData.rowSelectedObject.Invoice_SellerAddressLine,
                Invoice_SellerPhoneNumber: vueData.rowSelectedObject.Invoice_SellerPhoneNumber,
                Invoice_SellerFaxNumber: vueData.rowSelectedObject.Invoice_SellerFaxNumber,
                Invoice_SellerEmail: vueData.rowSelectedObject.Invoice_SellerEmail,
            }
            confirm({
                title: `<b>Xác nhận</b>`,
                message: `Cập nhật thông tin hoá đơn điện tử cho <b>${vueData.rowSelectedObject.TenCuaHang} </b>`,
                action: function () {
                    ajaxCALL("/eorder/CuaHang_Update_HoaDonDienTu", params, (res) => {
                        $this.vueData.isOpenDialogCTHoaDon = false
                        runAction(vueData.getCuaHang)
                        Vue.$toast.success("Cập nhật thông tin thành công", {
                            position: "top",
                        })
                    })
                },
            })
        },
    },
}
</script>

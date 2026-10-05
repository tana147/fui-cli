<template>
    <div class="page-section">
        <v-card @submit.prevent="callApi" elevation="0">
            <v-card-title>Thông tin công ty</v-card-title>
            <v-card-text>
                <div class="pb-4 mb-3">
                    <f-image-update v-model="vueData.DSCauHinh[0].Logo_Url" v-on:update="onUpload" :api-upload="vueData.v_Set.apiFile" w="4" label="Logo công ty" dialog-width="1000" dialog-height="600" :size="{width: 1000, height: 800}" quality="0.5" :croper-attr="{'default-size': {width: 1000, height: 400}, transitions: true, 'image-restriction': 'none'}" />
                </div>
                <v-row>
                    <v-col>
                        <v-text-field label="Tên công ty" v-model="vueData.DSCauHinh[0].TenCongTy" outlined dense hide-details />
                    </v-col>
                </v-row>
                <v-row>
                    <v-col>
                        <v-text-field label="Mã số thuế" v-model="vueData.DSCauHinh[0].MaSoThue" outlined dense hide-details />
                    </v-col>
                    <v-col>
                        <v-text-field type="number" label="Số điện thoại" v-model="vueData.DSCauHinh[0].DienThoai" outlined dense hide-details />
                    </v-col>
                </v-row>
                <v-row>
                    <v-col>
                        <v-text-field label="Email công ty" v-model="vueData.DSCauHinh[0].EmailCongTy" outlined dense hide-details />
                    </v-col>
                    <v-col>
                        <v-text-field label="Website" v-model="vueData.DSCauHinh[0].Website" outlined dense hide-details />
                    </v-col>
                </v-row>
                <v-row>
                    <v-col>
                        <v-textarea label="Địa chỉ" v-model="vueData.DSCauHinh[0].DiaChi" outlined hide-details rows="2" />
                    </v-col>
                </v-row>
                <v-card-title class="black--text mt-3 mb-1 pl-0">Mail hệ thống</v-card-title>
                <v-row>
                    <v-col>
                        <v-text-field label="Mail Server" v-model="vueData.DSCauHinh[0].MailServer" outlined dense hide-details />
                    </v-col>
                    <v-col>
                        <v-text-field label="Mail Address" v-model="vueData.DSCauHinh[0].MailAddress" outlined hide-details dense />
                    </v-col>
                </v-row>
                <v-row>
                    <v-col cols="6">
                        <v-text-field label="Mail Password" :type="showPassword ? 'text' : 'password'" :append-icon="showPassword ? 'mdi-eye' : 'mdi-eye-off'" @click:append="showPassword = !showPassword" v-model="vueData.DSCauHinh[0].MailPassword" outlined dense hide-details obscureText />
                    </v-col>
                    <v-col>
                        <v-text-field label="Mail Port " v-model="vueData.DSCauHinh[0].MailPort" outlined dense hide-details />
                    </v-col>
                    <v-col>
                        <v-select v-model="vueData.DSCauHinh[0].MailSsl" :items="vueData.DSCoKhong" label="Mail SSL" outlined dense></v-select>
                    </v-col>
                </v-row>
                <v-card-title class="black--text mt-3 mb-1 pl-0">GRAB Food API</v-card-title>
                <v-row>
                    <v-col cols="6">
                        <v-text-field label="Client Id" v-model="vueData.DSCauHinh[0].GrabClientId" outlined dense hide-details />
                    </v-col>
                    <v-col cols="6">
                        <v-text-field label="Client Secret" v-model="vueData.DSCauHinh[0].GrabClientSecret" :type="showPasswordGrab ? 'text' : 'password'" :append-icon="showPasswordGrab ? 'mdi-eye' : 'mdi-eye-off'" @click:append="showPasswordGrab = !showPasswordGrab" outlined dense hide-details obscureText  />
                    </v-col>
                    <v-col cols="6">
                        <v-text-field label="Grant Type" v-model="vueData.DSCauHinh[0].GrabGrantType" outlined dense hide-details />
                    </v-col>
                    <v-col cols="6">
                        <v-text-field label="Scope" v-model="vueData.DSCauHinh[0].GrabScope" outlined hide-details dense />
                    </v-col>
                    <v-col cols="12">
                        <v-textarea label="Order User Token (GRAB00001)" v-model="vueData.DSCauHinh[0].GrabOrderToken" outlined hide-details dense rows="2"/>
                    </v-col>
                </v-row>
                <v-card-title class="black--text mt-3 mb-1 pl-0">Viettel E-Invoice API</v-card-title>
                <v-row>
                    <v-col cols="6">
                        <v-text-field label="API User" v-model="vueData.DSCauHinh[0].ViettelInvoiceUser" outlined dense hide-details />
                    </v-col>
                    <v-col cols="6">
                        <v-text-field label="API Password" v-model="vueData.DSCauHinh[0].ViettelInvoicePassword" outlined hide-details :type="showPasswordHDDT ? 'text' : 'password'" :append-icon="showPasswordHDDT ? 'mdi-eye' : 'mdi-eye-off'" @click:append="showPasswordHDDT = !showPasswordHDDT" dense obscureText />
                    </v-col>
                </v-row>
            </v-card-text>
            <v-card-actions>
                <v-btn :loading="this.isLoading" @click="onUpdateConfig" elevation="0" color="primary"><v-icon left>mdi-content-save</v-icon>Lưu thiết lập</v-btn>
            </v-card-actions>
        </v-card>
    </div>
</template>

<script>
export default {
    props: [],
    data() {
        return {
            showPassword: false,
            showPasswordGrab: false,
            showPasswordHDDT: false,
        }
    },
    methods: {
        onUpload($event) {
            vueData.DSCauHinh[0].Logo_FileID = $event.returnData.Files[0].FileID
            vueData.DSCauHinh[0].Logo_Url = vueData.v_Set.urlReturnFile + $event.returnData.Files[0].Url
        },
        onUpdateConfig() {
            const params = vueData.DSCauHinh[0]
            ajaxCALL("/eorder/CauHinh_Update", params, (res) => {
                Vue.$toast.success("Lưu cấu hình thành công", {position: "top"})
            })
        },
    },
}
</script>

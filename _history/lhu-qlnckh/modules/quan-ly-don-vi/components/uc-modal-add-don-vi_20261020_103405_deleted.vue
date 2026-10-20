<template>
    <div>
        <v-dialog v-model="isOpen" max-width="600px">
            <v-card>
                <v-card-title>
                    <span class="text-h5 primary--text">Thêm mới đơn vị</span>
                    <v-spacer></v-spacer>
                    <v-btn fab small icon @click="onHandeCloseModal">
                        <v-icon>mdi-close</v-icon>
                    </v-btn>
                </v-card-title>
                <v-card-text>
                    <v-form ref="formRef" lazy-validation>
                        <v-row>
                            <v-col cols="12">
                                <v-text-field label="Mã đơn vị" v-model="formData.MaDonVi" outlined hide-details
                                    dense></v-text-field>
                            </v-col>
                            <v-col cols="12">
                                <v-text-field label="Tên đơn vị" v-model="formData.TenDonVi" outlined hide-details
                                    dense></v-text-field>
                            </v-col>
                        </v-row>
                    </v-form>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn text @click="onHandeCloseModal">
                        Đóng
                    </v-btn>
                    <v-btn text color="primary" @click="onAddItem">
                        Thêm mới
                    </v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>
<script>
export default {
    props: ['isOpen'],
    data() {
        return {
            formData: {
                MaDonVi: '',
                TenDonVi: ''
            }
        }
    },
    methods: {
        onHandeCloseModal() {
            this.$emit('updateIsOpen', false)
            this.$emit('onFinish')
            this.$refs.formRef.reset()
        },
        async onAddItem() {
            const $this = this
            const params = { ...$this.formData }
            await ajaxCALL('/DonVi_Ins', params, res => {
                if (res) {
                    $this.onHandeCloseModal()
                    Vue.$toast.success("Thêm đơn vị thành công!", { position: "top" })
                }
            }, error => {
                Vue.$toast.error(error.responseJSON.Message, { position: "top" });
                $this.onHandeCloseModal()
            })
        }
    }

}
</script>
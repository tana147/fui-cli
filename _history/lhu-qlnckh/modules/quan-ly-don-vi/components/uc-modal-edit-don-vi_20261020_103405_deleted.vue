<template>
    <div>
        <v-dialog v-model="isOpen" max-width="600px">
            <v-card>
                <v-card-title class="d-flex align-center">
                    <span class="primary--text">Cập nhật đơn vị</span>
                    <v-spacer></v-spacer>
                    <v-icon @click="onHandeCloseModal()">mdi-close</v-icon>
                </v-card-title>
                <v-card-text>
                    <v-form ref="formRef" lazy-validation>
                        <v-row>
                            <v-col cols="12">
                                <v-text-field label="Mã đơn vị" v-model="record.MaDonVi" outlined hide-details dense
                                    :disabled="true"></v-text-field>
                            </v-col>
                            <v-col cols="12">
                                <v-text-field label="Tên đơn vị" v-model="record.TenDonVi" outlined hide-details
                                    dense></v-text-field>
                            </v-col>
                        </v-row>
                    </v-form>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn text @click="onHandeCloseModal()">Đóng</v-btn>
                    <v-btn text color="primary" @click="onEditItem()">Cập nhật</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>
<script>
export default {
    props: ['isOpen', 'record'],
    data() {
        return {

        }
    },
    methods: {
        onHandeCloseModal() {
            this.$emit('updateIsOpen', false)
            this.$emit('onFinish')
            this.$refs.formRef.reset()
        },
        async onEditItem() {
            const $this = this
            const params = { ...$this.record }
            await ajaxCALL('/DonVi_Upd', params, res => {
                if (res) {
                    $this.onHandeCloseModal()
                    Vue.$toast.success("Cập nhật đơn vị thành công!", { position: "top" })
                }
            }, error => {
                Vue.$toast.error(error.responseJSON.Message, { position: "top" });
                $this.onHandeCloseModal()
            })
        }
    }

}
</script>
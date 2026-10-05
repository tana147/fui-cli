<template>
	<v-text-field ref="refSQD" v-model="FormatNgaySQD" v-bind="$attrs" @focus="onFoucs" @blur="onBlur" @keydown.enter="onEnter"></v-text-field>
</template>

<script>
	export default {
		props: ['ngay', 'thang', 'nam'],
    create() {},
    data() {
        return {
            NgaySoQD: this.FormatNgaySQD,
        }
    },
    mounted() {},
    computed: {
        FormatNgaySQD: function () {
            let convertDayString = ''
            let convertMonthString = ''
            let convertYearString = ''
            let date = ''

            if (this.ngay) {
                convertDayString = this.ngay.toString() + '/'
            }
            if (this.thang) {
                convertMonthString = (this.thang ? this.thang.toString().padStart(2, '0') : 0) + '/'
            }
            if (this.nam) {
                convertYearString = this.nam.toString()
            }

            date = convertDayString + convertMonthString + convertYearString
            this.$data.NgaySoQD = date
            return date
        },
    },
    watch: {},
    methods: {
        onFoucs(e) {
            const newValue = e.target.value.replaceAll('/', '')
            this.NgaySoQD = newValue
        },
        onBlur(e) {
            this.NgaySoQD = this.onChangeValue(e.target.value)
        },
        onEnter(e) {
            this.NgaySoQD = this.onChangeValue(e.target.value)
            this.$refs.refSQD.blur()
        },
        onChangeValue(value) {
            let strCurrentValue = value
            const curMonth = new Date().getMonth() + 1
            const curYear = new Date().getFullYear()

            let newValue = ''
            if (strCurrentValue.length === 1) {
                //Nếu len = 1 thì nhập ngày
                const ddValue = strCurrentValue.substring(0, 1)
                const dd = ddValue < 10 ? '0' + ddValue : ddValue
                const mm = curMonth < 10 ? '0' + curMonth : curMonth
                const yyyy = curYear
                this.emitDate(dd, mm, yyyy)
                newValue = `${dd}/${mm}/${yyyy}`
            } else if (strCurrentValue.length === 2) {
                //Nếu len = 2 thì vẫn nhập ngày
                const dd = strCurrentValue.substring(0, 2)
                const mm = curMonth < 10 ? '0' + curMonth : curMonth
                const yyyy = curYear
                this.emitDate(dd, mm, yyyy)
                newValue = `${dd}/${mm}/${yyyy}`
            } else if (strCurrentValue.length === 4) {
                //Nếu len == 4 thì nhập ngày/tháng
                const dd = strCurrentValue.substring(0, 2)
                const mm = strCurrentValue.substring(2, 4)
                const yyyy = curYear

                this.emitDate(dd, mm, yyyy)

                newValue = `${dd}/${mm}/${yyyy}`
            } else if (strCurrentValue.length === 5) {
                //Nếu len == 5 thì nhập tháng/năm
                const dd = null
                const mm = strCurrentValue.substring(0, 1).padStart(2, '0')
                const yyyy = strCurrentValue.substring(1, 5)

                this.emitDate(dd, mm, yyyy)

                newValue = `${mm}/${yyyy}`
            } else if (strCurrentValue.length === 6) {
                //Nếu len == 6 thì nhập tháng/năm
                const dd = null
                const mm = strCurrentValue.substring(0, 2)
                const yyyy = strCurrentValue.substring(2, 6)

                this.emitDate(dd, mm, yyyy)

                newValue = `${mm}/${yyyy}`
            } else if (strCurrentValue.length === 8) {
                //Nếu len == 4 thì nhập ngày/tháng/năm
                const dd = strCurrentValue.substring(0, 2)
                const mm = strCurrentValue.substring(2, 4)
                const yyyy = strCurrentValue.substring(4, 8)

                this.emitDate(dd, mm, yyyy)

                newValue = `${dd}/${mm}/${yyyy}`
            } else if (strCurrentValue.length === 10) {
                let split = strCurrentValue.split('/')
                this.emitDate(split[0], split[1], split[2])
                newValue = strCurrentValue
            }
            return newValue
        },
        emitDate(ngay, thang, nam) {
            this.$emit('update:ngay', ngay)
            this.$emit('update:thang', thang)
            this.$emit('update:nam', nam)
        },
    },
	}
</script>
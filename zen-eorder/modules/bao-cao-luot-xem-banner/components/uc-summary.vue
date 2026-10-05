<template>
    <div>
           <v-row class="row-report-summary" >
            <v-col cols="2">
               Tổng số lượt quét poster <br/> <b class="red--text">{{ vueData.DataSummary?.sumScanPoster ?? 0 }}</b>
            </v-col>
            <v-col cols="2">
               Tổng mã QR <br/> <b class="red--text">{{ vueData.DataSummary?.sumQrCode / 2 ?? 0 }}</b>
            </v-col>
              <v-col cols="2">
               Tổng số lượt bấm xem tiếp<br/> <b class="red--text">{{ vueData.DataSummary?.sumNextView ?? 0 }}</b>
            </v-col>
            <v-col cols="2">
               Tỷ lệ quét QR (%)/ Tổng số QR <br/> <b class="red--text">{{ vueData.DataSummary?.percentScanPoster ?? 0 }}%</b>
            </v-col>
             <v-col cols="2">
              Giao diện có lượt quét cao nhất <br/> <b class="red--text">{{  vueData.DataSummary?.topInterfaceByScans?.name }}({{ vueData.DataSummary?.topInterfaceByScans?.percent }}%)</b>
            </v-col>
        </v-row>
    </div>
</template>
<script>
export default {
    methods: {
        
    },
}
</script>
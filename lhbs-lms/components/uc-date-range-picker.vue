<template>
	<v-menu v-model="menuOpen" :close-on-content-click="false" location="bottom start" offset="8">
    <template #activator="{ props }">
      <v-btn v-bind="props" variant="outlined" color="primary" prepend-icon="mdi-calendar-range" :append-icon="menuOpen ? 'mdi-chevron-up' : 'mdi-chevron-down'" class="uc-date-range-picker__trigger">
        <template v-if="picking.from && picking.to">{{ formatDisplay(picking.from) }} <v-icon size="14" class="mx-1">mdi-arrow-right</v-icon> {{ formatDisplay(picking.to) }}</template>
        <span v-else class="text-medium-emphasis">Chọn khoảng thời gian</span>
      </v-btn>
    </template>
    <v-card class="uc-date-range-picker__card" rounded="lg" elevation="8" border>
      <div class="d-flex align-center justify-space-between px-4 pt-3 pb-2 ga-3">
        <span class="text-subtitle-2 font-weight-bold">Khoảng thời gian</span>
        <div class="d-flex ga-1 flex-wrap justify-end">
          <v-chip v-for="s in shortcuts" :key="s.label" size="x-small" variant="tonal" color="primary" label class="cursor-pointer" @click="applyShortcut(s)">{{ s.label }}</v-chip>
        </div>
      </div>
      <v-divider />
      <div class="uc-date-range-picker__calendars">
        <div class="uc-date-range-picker__calendar">
          <div class="d-flex align-center ga-1 px-4 pt-3 pb-1">
            <v-icon size="15" color="primary">mdi-calendar-start</v-icon>
            <span class="text-caption font-weight-bold text-primary text-uppercase">Từ ngày</span>
            <v-chip v-if="picking.from" size="x-small" color="primary" variant="tonal" label class="ml-1">{{ formatDisplay(picking.from) }}</v-chip>
          </div>
          <v-date-picker :model-value="isoToDate(picking.from)" :max="isoToDate(picking.to)" hide-header show-adjacent-months color="primary" elevation="0" class="uc-date-range-picker__date-picker" @update:model-value="onPickFrom" />
        </div>
        <v-divider vertical />
        <div class="uc-date-range-picker__calendar">
          <div class="d-flex align-center ga-1 px-4 pt-3 pb-1">
            <v-icon size="15" color="success">mdi-calendar-end</v-icon>
            <span class="text-caption font-weight-bold text-success text-uppercase">Đến ngày</span>
            <v-chip v-if="picking.to" size="x-small" color="success" variant="tonal" label class="ml-1">{{ formatDisplay(picking.to) }}</v-chip>
          </div>
          <v-date-picker :model-value="isoToDate(picking.to)" :min="isoToDate(picking.from)" hide-header show-adjacent-months color="success" elevation="0" class="uc-date-range-picker__date-picker" @update:model-value="onPickTo" />
        </div>
      </div>
      <v-divider />
      <div class="d-flex align-center px-4 py-2 ga-3">
        <div class="d-flex align-center ga-2">
          <v-chip size="small" :color="picking.from ? 'primary' : 'default'" :variant="picking.from ? 'tonal' : 'outlined'" label prepend-icon="mdi-calendar-start">{{ picking.from ? formatDisplay(picking.from) : 'Từ ngày' }}</v-chip>
          <v-icon size="16">mdi-arrow-right</v-icon>
          <v-chip size="small" :color="picking.to ? 'success' : 'default'" :variant="picking.to ? 'tonal' : 'outlined'" label prepend-icon="mdi-calendar-end">{{ picking.to ? formatDisplay(picking.to) : 'Đến ngày' }}</v-chip>
        </div>
        <v-spacer />
        <v-btn variant="text" size="small" color="error" @click="onClear"><v-icon start size="14">mdi-close</v-icon>Xóa</v-btn>
        <v-btn variant="tonal" size="small" color="primary" :disabled="!picking.from || !picking.to" @click="onApply"><v-icon start size="14">mdi-check</v-icon>Áp dụng</v-btn>
      </div>
    </v-card>
  </v-menu>
</template>

<script>
	export default {
		props: { modelValue: { type: Object, default: function(){ return { from:null, to:null } } } },
  emits: ['update:modelValue'],
  data(){
    // Mặc định mở theo toàn bộ tháng hiện tại để màn hình báo cáo có phạm vi vừa đủ, không phải tải cả lịch sử.
    const now = new Date()
    const dateToISO = d => d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0')
    const defaultRange = { from: dateToISO(new Date(now.getFullYear(), now.getMonth(), 1)), to: dateToISO(new Date(now.getFullYear(), now.getMonth()+1, 0)) }
    const hasIncomingRange = this.modelValue?.from || this.modelValue?.to
    const initialRange = hasIncomingRange ? { from:this.modelValue?.from||null, to:this.modelValue?.to||null } : defaultRange
    return { menuOpen:false, picking:initialRange, shortcuts:[
    {label:'Hôm nay',fn:()=>{const t=this.dateToISO(new Date());return{from:t,to:t}}},
    {label:'Tuần này',fn:()=>this.currentWeek()}, {label:'Tháng này',fn:()=>this.currentMonth()}, {label:'Tháng trước',fn:()=>this.lastMonth()},
    {label:'Học kỳ 1',fn:()=>this.hocKy(1)}, {label:'Học kỳ 2',fn:()=>this.hocKy(2)}
  ]}
  },
  mounted(){
    // Đồng bộ khoảng mặc định lên component cha để lần Tra cứu đầu tiên dùng đúng tháng hiện tại.
    if (!this.modelValue?.from && !this.modelValue?.to) this.$emit('update:modelValue',{...this.picking})
  },
  watch:{ modelValue:{deep:true,handler(v){this.picking={from:v?.from||null,to:v?.to||null}}}, menuOpen(v){if(v)this.picking={from:this.modelValue?.from||null,to:this.modelValue?.to||null}} },
  methods:{
    isoToDate(v){if(!v)return null;const p=v.split('-').map(Number);return new Date(p[0],p[1]-1,p[2])},
    dateToISO(d){if(!d)return null;return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0')},
    formatDisplay(v){if(!v)return'';const p=v.split('-');return p[2]+'/'+p[1]+'/'+p[0]},
    onPickFrom(v){this.picking.from=this.dateToISO(v);if(this.picking.to&&this.picking.from>this.picking.to)this.picking.to=null},
    onPickTo(v){this.picking.to=this.dateToISO(v)},
    onApply(){this.$emit('update:modelValue',{...this.picking});this.menuOpen=false},
    onClear(){this.picking={from:null,to:null};this.$emit('update:modelValue',{from:null,to:null});this.menuOpen=false},
    applyShortcut(s){this.picking=s.fn();this.$emit('update:modelValue',{...this.picking});this.menuOpen=false},
    currentWeek(){const n=new Date(),d=n.getDay()||7,f=new Date(n);f.setDate(n.getDate()-d+1);const t=new Date(f);t.setDate(f.getDate()+6);return{from:this.dateToISO(f),to:this.dateToISO(t)}},
    currentMonth(){const n=new Date();return{from:this.dateToISO(new Date(n.getFullYear(),n.getMonth(),1)),to:this.dateToISO(new Date(n.getFullYear(),n.getMonth()+1,0))}},
    lastMonth(){const n=new Date();return{from:this.dateToISO(new Date(n.getFullYear(),n.getMonth()-1,1)),to:this.dateToISO(new Date(n.getFullYear(),n.getMonth(),0))}},
    hocKy(k){const n=new Date(),y=n.getMonth()+1>=8?n.getFullYear():n.getFullYear()-1;return k===1?{from:y+'-08-01',to:y+'-12-31'}:{from:(y+1)+'-01-01',to:(y+1)+'-05-31'}}
  }
	}
</script>

<style scoped>
/*
 * Menu content is teleported to body by v-menu, so the shared responsive
 * layout must live here instead of in a module-scoped stylesheet.
 */
.uc-date-range-picker__card {
  width: min(680px, calc(100vw - 24px));
  overflow: hidden;
}

.uc-date-range-picker__calendars {
  display: flex;
}

.uc-date-range-picker__calendar {
  flex: 1;
  min-width: 0;
}

.uc-date-range-picker__date-picker {
  width: 100%;
  border-radius: 0;
  box-shadow: none;
}

@media (max-width: 600px) {
  .uc-date-range-picker__card {
    width: calc(100vw - 16px);
  }

  .uc-date-range-picker__calendars {
    display: block;
    max-height: 62vh;
    overflow-y: auto;
  }

  .uc-date-range-picker__calendars > .v-divider {
    display: none;
  }

  .uc-date-range-picker__calendar + .uc-date-range-picker__calendar {
    border-top: 1px solid rgba(0, 0, 0, .12);
  }
}
</style>
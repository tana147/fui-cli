<template>
  <div ref="chartEl"></div>
</template>

<script>
export default {
  props: {
    options: {
      type: Object,
      required: true,
      validator: function(value) {
        return value && typeof value === 'object';
      }
    }
  },
  
  data() {
    return {
      myChart: null
    }
  },

  mounted() {
    this.buildChart()
  },

  watch: {
    options: {
      deep: true,
      handler(newVal, oldVal) {
        if (this.myChart && newVal !== oldVal) {
          try {
            this.myChart.destroy()
            this.buildChart()
          } catch (error) {
            console.error('Error updating chart:', error)
          }
        }
      }
    }
  },

  methods: {
    buildChart() {
      try {
        const chartOptions = {
          ...this.options,
          chart: {
            ...this.options.chart,
            events: {
              ...this.options.chart?.events,
              beforeMount: (chart) => {
                // Add passive event listeners
                chart.el.addEventListener('touchstart', () => {}, { passive: true })
                chart.el.addEventListener('touchmove', () => {}, { passive: true })
                chart.el.addEventListener('wheel', () => {}, { passive: true })
                
                // Call original beforeMount if exists
                if (this.options.chart?.events?.beforeMount) {
                  this.options.chart.events.beforeMount(chart)
                }
              }
            }
          }
        }

        this.myChart = new ApexCharts(this.$refs.chartEl, chartOptions)
        this.myChart.render()
      } catch (error) {
        console.error('Error building chart:', error)
      }
    },

    destroyChart() {
      if (this.myChart) {
        try {
          this.myChart.destroy()
          this.myChart = null
        } catch (error) {
          console.error('Error destroying chart:', error)
        }
      }
    }
  },

  beforeUnmount() {
    this.destroyChart()
  }
}
</script>

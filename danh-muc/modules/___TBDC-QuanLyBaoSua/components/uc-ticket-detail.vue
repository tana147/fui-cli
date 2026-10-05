<template>
	<v-container>
		<v-card class="mb-5" elevation="2">
			<v-card-title class="text-h6">Thông tin tài sản</v-card-title>
			<v-card-text>
				<div><strong>Tên tài sản:</strong> Laptop Dell XPS 13</div>
				<div><strong>Mã tài sản:</strong> TS00123</div>
			</v-card-text>
		</v-card>

		<v-expansion-panels v-model="panel" variant="accordion" class="accordion-custom">
			<v-expansion-panel v-for="(step, index) in steps" :key="index" :ref="setStepRefs">
				<!-- Slot title KHÔNG destructuring -->
				<template #title>
					<div class="d-flex align-center w-100">
						<v-icon class="mr-2">{{ step.icon }}</v-icon>
						<span class="text-subtitle-1 font-weight-bold">{{ step.title }}</span>

						<v-spacer></v-spacer>

						<v-chip :color="step.statusColor" size="small" text-color="white" class="mr-2">
							{{ step.status }}
						</v-chip>
					</div>
				</template>

				<v-expansion-panel-text>
					<div class="text-caption mb-2">
						<strong>Thời gian:</strong> {{ step.time }}
					</div>
					<div class="text-caption mb-2">
						<strong>Người thực hiện:</strong> {{ step.user }}
					</div>
					<div class="text-caption">
						<strong>Ghi chú:</strong> {{ step.note }}
					</div>
				</v-expansion-panel-text>
			</v-expansion-panel>
		</v-expansion-panels>
	</v-container>
</template>

<script>
	export default {
    data() {
      return {
        steps: [
          {
            title: 'Báo sửa',
            time: '2025-04-27 10:30',
            user: 'Nguyễn Văn A',
            note: 'Laptop không khởi động được.',
            status: 'Hoàn thành',
            statusColor: 'green',
            icon: 'mdi-alert-circle',
          },
          {
            title: 'Tiếp nhận báo sửa',
            time: '2025-04-27 11:00',
            user: 'Trần Thị B',
            note: 'Đã nhận laptop, chờ kiểm tra.',
            status: 'Hoàn thành',
            statusColor: 'green',
            icon: 'mdi-handshake',
          },
          {
            title: 'Kiểm tra',
            time: '2025-04-27 14:00',
            user: 'Phạm Văn C',
            note: 'Kiểm tra mainboard, nghi lỗi IC nguồn.',
            status: 'Đang xử lý',
            statusColor: 'blue',
            icon: 'mdi-magnify',
          },
          {
            title: 'Sửa chữa',
            time: '2025-04-28 09:00',
            user: 'Lê Thị D',
            note: 'Chưa thực hiện.',
            status: 'Chưa thực hiện',
            statusColor: 'grey',
            icon: 'mdi-tools',
          },
        ],
        panel: null,
        stepRefs: [],
      }
    },
    mounted() {
      // const activeIndex = this.steps.findIndex(
      //   step => step.status === 'Đang xử lý'
      // )
      // if (activeIndex !== -1) {
      //   this.panel = activeIndex
      //   this.$nextTick(() => {
      //     this.scrollToStep(activeIndex)
      //   })
      // }
    },
    methods: {
      setStepRefs(el) {
        if (el) {
          this.stepRefs.push(el)
        }
      },
      scrollToStep(index) {
        const el = this.stepRefs[index]?.$el
        if (el) {
          el.scrollIntoView({ behavior: 'smooth', block: 'center' })
        }
      },
    }
  }
</script>

<style scoped>
	.accordion-custom {
		max-width: 800px;
		margin: auto;
	}

	.v-expansion-panel-title {
		min-height: 56px;
	}

	.v-expansion-panel-text {
		padding-top: 8px;
		padding-bottom: 16px;
	}
</style>
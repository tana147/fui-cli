<template>
	<div :style="avatarStyle" class="uc-avatar">
		<img v-if="image" :src="image" :alt="name"
			style="width: 100%; height: 100%; object-fit: cover; border-radius: 50%;" />
		<span v-else>{{ initials }}</span>
	</div>
</template>

<script>
	export default {
		name: 'uc-avatar',
  props: {
    name: { type: String, default: '' },
    size: { type: [Number, String], default: 24 },
    fontSize: { type: String, default: '' },
    image: { type: String, default: '' }
  },
  data: function () {
    return {}
  },
  computed: {
    initials: function () {
      if (!this.name) return ''
      const parts = String(this.name).trim().split(/\s+/)
      if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase()
      const word1 = parts[parts.length - 2] || ''
      const word2 = parts[parts.length - 1] || ''
      return (word1.charAt(0) + word2.charAt(0)).toUpperCase()
    },
    avatarStyle: function () {
      let hash = 0
      const str = String(this.name || '')
      for (let i = 0; i < str.length; i++) {
        hash = str.charCodeAt(i) + ((hash << 5) - hash)
      }

      // Tính toán Hue (màu sắc) từ 0 đến 360 độ dựa trên hash
      const hue = Math.abs(hash) % 360
      // Độ bão hòa cố định 60% và độ sáng cố định 45% để đảm bảo chữ trắng tương phản cực đẹp
      const bgColor = 'hsl(' + hue + ', 60%, 45%)'

      const sz = typeof this.size === 'number' ? this.size + 'px' : this.size
      const fs = this.fontSize ? this.fontSize : (parseFloat(sz) * 0.4) + 'px'

      return {
        width: sz,
        height: sz,
        minWidth: sz,
        fontSize: fs,
        backgroundColor: this.image ? 'transparent' : bgColor,
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontWeight: 'bold',
        color: '#ffffff',
        borderRadius: '50%',
        textTransform: 'uppercase',
        userSelect: 'none',
        flexShrink: 0
      }
    }
  }
	}
</script>
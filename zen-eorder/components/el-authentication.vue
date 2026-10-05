<script>
	export default {
		props: [],
		data() {
			return {
				RightId_List: [],
				GroupId_List: []
			}
		},
		mounted() {
			if (vueData.user.UserID) {
				const navMenu = document.getElementsByClassName('v-navigation-drawer__content')[0]
				navMenu.classList.add("d-none");
				this.getRightByUserId()
			}
		},
		methods: {
			getRightByUserId() {
				const $this = this
				ajaxCALL('/eorder/NhanVien_Select_ById', {}, (res) => {
					if (res.data) {
						const resRight = res.data[0]
						const rightList = resRight.map((item) => item.QuyenID)
						const groupList = resRight.map((item) => item.NhomQuyen)
						$this.RightId_List = rightList
						$this.GroupId_List = groupList
						$this.menuAuthentication()
						const navMenu = document.getElementsByClassName('v-navigation-drawer__content')[0]
						navMenu.classList.remove("d-none");
					}
				})
			},
			menuAuthentication() {
				const $this = this
				const menuLeftClone = JSON.parse(JSON.stringify(vueData.v_Set.menuLeft))
				menuLeftClone.forEach((item, index) => {
					// Nếu có submenu
					if (item.submenu && item.submenu.length > 0) {
						// Xử lý group
						if ($this.GroupId_List.indexOf(item.groupId) < 0) {
							const indexMenu = vueData.v_Set.menuLeft.findIndex(fi => fi.groupId === item.groupId);
							if (indexMenu >= 0) {
								vueData.v_Set.menuLeft.splice(indexMenu, 1)
							}
						}
						// Xử lý menu con
						item.submenu.forEach((subItem, subIndex) => {
							if ($this.RightId_List.indexOf(subItem.rightId) < 0 && $this.RightId_List.indexOf(subItem.funcId) < 0) {
								const indexMenu = vueData.v_Set.menuLeft.findIndex(fi => fi.groupId === item.groupId);
								const indexSubMenu = vueData.v_Set.menuLeft[indexMenu]?.submenu?.findIndex(fi => fi.rightId === subItem.rightId);
								if (indexSubMenu >= 0) {
									vueData.v_Set.menuLeft[indexMenu].submenu.splice(indexSubMenu, 1)
								}
							}
						})
					}
					// Không có submenu
					else {
						if ($this.RightId_List.indexOf(item.rightId) < 0 && $this.RightId_List.indexOf(item.funcId) < 0) {
							const indexMenu = vueData.v_Set.menuLeft.findIndex(fi => fi.rightId === item.rightId);
							if (indexMenu >= 0) {
								vueData.v_Set.menuLeft.splice(indexMenu, 1)
							}
						}
					}
				})
	
			}
		},
	}
</script>
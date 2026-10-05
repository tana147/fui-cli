<template>
	<div class="app-container-improved">

		<!-- LOADING OVERLAY -->
		<div v-if="menubookLoading && loadingMessage" class="loading-overlay">
			<div class="loading-content">
				<v-progress-circular indeterminate color="primary" size="48"></v-progress-circular>
				<p>{{ loadingMessage }}</p>
			</div>
		</div>

		<!-- HEADER - COMPACT -->
		<div class="app-header-improved">
			<div class="app-title-improved">
				<i class="mdi mdi-silverware-fork-knife"></i>
				<span>Menu Designer</span>
				<small v-if="currentMenubookInfo && currentMenubookInfo.MenuBookID">
					(Tên menu: {{ currentMenubookInfo.TenBook }})
					- Tình trạng: {{ currentMenubookInfo.Is_TamKhoa == 1 ? 'Tạm khóa' : 'Mở' }}
				</small>
			</div>
			<!-- DEVICE SELECTOR - ICONS ONLY -->
			<div class="device-selector-improved" v-if="currentPage">
				<button v-for="deviceType in ['Desktop', 'Tablet', 'Mobile']" :key="deviceType"
					class="device-btn-improved" :class="{ active: currentPage.type === deviceType }"
					@click="changePageType(deviceType)" :title="deviceType">
					<i :class="getDeviceIcon(deviceType)"></i>
				</button>
			</div>

			<!-- ACTION BUTTONS - SIMPLIFIED -->
			<div class="header-actions-improved">
				<button class="action-btn-improved" @click="goBackToMenuList">
					<i class="mdi mdi-arrow-left"></i>
					<span>Quay lại</span>
				</button>
				<button class="action-btn-improved" @click="showJsonEditor = !showJsonEditor">
					<i class="mdi mdi-code-json"></i>
					<span>{{ showJsonEditor ? 'Ẩn JSON' : 'Xem JSON' }}</span>
				</button>
				<button class="action-btn-improved" @click="openImportDialog">
					<i class="mdi mdi-eye-outline"></i>
					<span>Preview</span>
				</button>
				<button class="action-btn-improved" @click="saveMenu">
					<i class="mdi mdi-content-save"></i>
					<span>Lưu Menu</span>
				</button>
				<button class="action-btn-improved" v-if="selectedIds.length" @click="deleteSelected"
					title="Xoá tất cả phần tử đang chọn">
					<i class="mdi mdi-delete"></i>
					<span>Xoá lựa chọn</span>
				</button>
			</div>
		</div>

		<!-- LEFT SIDEBAR - ALWAYS VISIBLE -->
		<div class="left-sidebar-improved">
			<!-- <v-select v-model="vueData.CuaHangID_Local" :items="vueData.DSCuaHang" item-value="CuaHangID"
						item-text="TenCuaHang" label="Chọn cửa hàng" outlined dense style="flex: unset; padding: 8px"
						hide-details /> -->
			<!-- Sidebar Header -->
			<!-- <div class="sidebar-header-improved">
						<div class="sidebar-title-improved">
							<i class="mdi mdi-menu"></i>
							<span>Thư viện</span>
						</div>
					</div> -->

			<!-- Sidebar Content -->
			<div class="sidebar-content-improved">
				<!-- MENU ITEMS SECTION -->
				<div class="sidebar-section-improved">
					<div class="section-header-improved">
						<i class="mdi mdi-food"></i>
						<span>Món ăn</span>
					</div>
					<div class="section-content-improved pa-2">
						<div class="search-box-improved">
							<input v-model="searchQuery" type="text" class="search-input-improved"
								placeholder="Tìm món ăn..." />
						</div>

						<!-- Loading State -->
						<div v-if="isLoading" class="empty-state">
							<v-skeleton-loader v-for="i in 3" :key="'loader-' + i" type="list-item-avatar-two-line"
								class="mb-2"></v-skeleton-loader>
						</div>

						<!-- Menu Items -->
						<div v-else class="menu-items-improved">
							<div v-if="!filteredItems.length" class="empty-state">
								Không tìm thấy món ăn nào.
							</div>
							<div v-for="(item, index) in filteredItems" :key="index" class="menu-item-improved"
								draggable="true" @dragstart="onDragStart($event, item, 'menu-item')">
								<img :src="item.image" class="menu-item-image-improved" :alt="item.name" />
								<div class="menu-item-info-improved">
									<div class="menu-item-name-improved">{{ item.stt }}. {{ item.name }}</div>
									<div class="menu-item-price-improved">{{ item.price }}</div>
								</div>
							</div>
						</div>
					</div>
				</div>

				<v-expansion-panels multiple v-model="expandedPanels">
					<!-- Hình ảnh -->
					<v-expansion-panel>
						<v-expansion-panel-header style="min-height:36px"
							class="section-header-improved d-flex justify-center align-center">
							<i class="mdi mdi-image-multiple d-flex justify-center align-center"></i>
							<span class="d-flex justify-center align-center">Hình ảnh</span>
							<f-file-upload-multi color="primary" type="MENU_IMG" style="width: 12px; height:12px"
								:elevation="0" :url="vueData.v_Set.apiFile" :filters="vueData.fileEX" :multiple=true
								class="d-flex justify-center align-center" @reload="loadAssets" />
						</v-expansion-panel-header>
						<v-expansion-panel-content>
							<div class="section-content-improved">
								<div class="assets-grid-improved">
									<div v-for="(src, index) in imageAssets" :key="'img-asset-' + index"
										class="asset-item-improved" draggable="true"
										@dragstart="onDragStart($event, src.AnhQuangCao_Url, 'image')">
										<img :src="src.AnhQuangCao_Url" :alt="'Asset ' + (index + 1)" />
										<v-btn x-small="" fab @click="deleteIMG(src.HinhAnhQuangCaoID)"
											class="mt-2 me-2" style="position: absolute; top: 5px;right: 5px;">
											<v-icon>mdi-close</v-icon>
										</v-btn>
									</div>
								</div>
							</div>
						</v-expansion-panel-content>
					</v-expansion-panel>

					<!-- Nền trang -->
					<v-expansion-panel class="mt-0">
						<v-expansion-panel-header style="min-height:36px" class="section-header-improved">
							<i class="mdi mdi-palette d-flex justify-center align-center"></i>
							<span class="d-flex justify-center align-center">Nền trang</span>
							<f-file-upload-multi color="primary" type="MENU_BG" style="width: 12px; height:12px"
								:elevation="0" :url="vueData.v_Set.apiFile" :filters="vueData.fileEX" :multiple=true
								class="d-flex justify-center align-center" @reload="loadAssets_bg" />
						</v-expansion-panel-header>
						<v-expansion-panel-content>
							<div class="section-content-improved">
								<div class="assets-grid-improved">
									<div v-for="(bg, index) in backgroundAssets" :key="'bg-asset-' + index"
										class="asset-item-improved" @click="setBackground(bg.AnhQuangCao_Url)"
										:title="'Background ' + (index + 1)">
										<img :src="bg.AnhQuangCao_Url" :alt="'Background ' + (index + 1)" />
										<v-btn x-small="" fab @click.stop="deleteIMG(bg.HinhAnhQuangCaoID)"
											style="position: absolute;top: 5px;right: 5px;">
											<v-icon>mdi-close</v-icon>
										</v-btn>
									</div>
								</div>
							</div>
						</v-expansion-panel-content>
					</v-expansion-panel>
				</v-expansion-panels>
			</div>
		</div>

		<!-- MAIN WORKSPACE -->
		<div class="main-workspace-improved">
			<div class="design-canvas-improved" v-if="currentPage" ref="canvas" @click.self="deselectAll"
				@dragover.prevent @drop="onDrop" :style="{
    			width: pageDimensions[currentPage.type].width + 'px',
    			height: pageDimensions[currentPage.type].height + 'px',
    			transform: 'scale(' + (zoomLevel * 1.1) + ')',
    			transformOrigin: 'left top',
    			margin: 'auto'
			}">
				<!-- Canvas Background -->
				<div class="canvas-background-improved"
					:style="{ backgroundImage: currentPage.background ? 'url(' + currentPage.background + ')' : 'none' }">
				</div>

				<!-- Elements Overlay -->
				<div class="elements-overlay-improved">
					<!-- IMAGE ELEMENTS -->
					<template v-for="el in currentPage.elements">
						<div v-if="el.type === 'image-element'" :key="el.id" class="canvas-element-improved"
							:class="{ 'is-selected': isSelectedId(el.id) }" :style="{
						       position: 'absolute',
						       left: el.x + 'px',
						       top: el.y + 'px',
						       zIndex: el.zIndex || 1
						     }" @mousedown="startDrag(el, $event, 'element')">

							<button v-show="isSelectedId(el.id)" class="control-btn-improved"
								@click.stop="deleteElement(el)">×</button>

							<img :src="el.src" :style="{
								width: el.width + 'px',
								height: el.height + 'px',
								transform: 'rotate(' + (el.rotation || 0) + 'deg)',
								pointerEvents: 'none',
								...(el.style || {})
							}" />
						</div>

						<!-- GROUP ELEMENTS -->
						<div v-if="el.type === 'group'" :key="el.id"
							class="canvas-element-group-improved border-draggable"
							:class="{'is-selected-group': isSelectedId(el.id) || isAnyChildSelected(el)}" :style="{
							    position: 'absolute',
							    left: el.x + 'px',
							    top: el.y + 'px',
							    width: el.width + 'px',
							    height: el.height + 'px',
								cursor: (draggingElement && draggingElement.id === el.id) || (selectedElement && selectedElement.id === el.id) ? 'move' : ''
							  }" @mousedown.stop="startDrag(el, $event, 'group')">

							<template v-if="selectedElement && selectedElement.id === el.id">
								<div v-for="pos in ['nw','ne','sw','se']" :key="pos" class="resize-handle"
									:class="'handle-' + pos" @mousedown.stop.prevent="startResize(el, $event, pos)">
								</div>
							</template>

							<!-- Group Controls -->
							<div class="group-controls-improved">
								<button class="control-btn-improved" @click.stop="deleteElement(el)">×</button>
							</div>

							<!-- Group Children -->
							<div v-for="child in el.children" :key="child.id" class="group-child-improved"
								:class="{  'is-selected-child': isSelectedId(child.id)}" :style="{
										position: 'absolute',
										left: child.relative_x + 'px',
										top: child.relative_y + 'px',
										zIndex: child.zIndex || 2
									}" @mousedown.stop="startDrag(child, $event, 'child')">
								<!-- Nút xoá chung cho mọi loại con -->
								<div v-if="selectedElement && selectedElement.id === child.id"
									style="position: absolute; top: -10px; right: -10px; z-index: 10;">
									<button @click.stop="deleteChildElement(el, child)"
										style="background-color: red; color: white; border: none; padding: 1px 3px; font-size: 5px; border-radius: 3px;">
										x
									</button>
								</div>
								<!-- Image Element -->
								<div v-if="child.type === 'image-element'" :style="{
									  position: 'relative',
									  zIndex: child.zIndex || 1
									}">
									<img v-if="child.src" :src="child.src" :style="{
											width: child.width + 'px',
											height: child.height + 'px',
											transform: 'rotate(' + (child.rotation || 0) + 'deg)',
											...child.style
										}" :alt="'Child ' + child.id" />
									<div v-else :style="{
											width: child.width + 'px',
											height: child.height + 'px',
											border: '1px dashed #ccc',
											display: 'flex',
											alignItems: 'center',
											justifyContent: 'center',
											backgroundColor: '#f0f0f0',
											fontSize: '12px',
											color: '#999'
										}">
										Kéo hình vào
									</div>

									<!-- Image Controls -->
									<!-- <div v-if="selectedElement && selectedElement.id === child.id"
											style="position: absolute; top: 0; right: 0; display: flex; gap: 4px;">
											<button
												style="background-color: rgba(0, 0, 0, 0.6); color: white; border: none; cursor: pointer; font-size: 12px; padding: 2px 6px; border-radius: 3px;"
												@click.stop="removeImage(child)">
												🗑
											</button>
										</div> -->
								</div>

								<!-- Text Element -->
								<div v-if="child.type === 'text-element'" :style="{
										...child.style,
										whiteSpace: 'pre-line',
										display: 'inline-block',
										lineHeight: child.style.lineHeight || '1.2',
										textAlign: child.style.textAlign || 'left'
									}">
									{{ child.content }}
								</div>
							</div>
						</div>
					</template>
				</div>
			</div>
		</div>

		<!-- RIGHT SIDEBAR - PROPERTIES -->
		<div class="right-sidebar-improved">
			<!-- Properties Section -->
			<div class="properties-section-improved pa-0">
				<div class="properties-container-improved" style="padding: 8px">
					<h4>
						<i class="mdi mdi-pencil"></i>
						Chỉnh sửa thuộc tính
					</h4>
					<hr style="margin: 8px 0; border: none; border-top: 1px solid #eee;" />

					<!-- Selected Element Properties -->
					<div v-if="selectedElement">
						<!-- Text Element Properties -->
						<div v-if="selectedElement.type === 'text-element'" class="properties-panel-improved">
							<div class="prop-item-improved">
								<label>Nội dung</label>
								<v-textarea outlined rows="4" v-model="selectedElement.content" @input="updateJson"
									:disabled="selectedElement.role === 'stt'" style="resize: vertical; width: 100%;" />
							</div>
							<div class="prop-item-improved">
								<button class="json-btn-improved"
									@click="addContentToGroup(selectedElement.groupId || (getParentGroupId(selectedElement) || null))">
									<i class="mdi mdi-plus"></i> Thêm nội dung
								</button>
							</div>
							<div class="prop-item-improved">
								<label>Căn lề</label>
								<select v-model="selectedElement.style.textAlign" @change="updateJson">
									<option value="left">Trái</option>
									<option value="center">Giữa</option>
									<option value="right">Phải</option>
								</select>
							</div>
							<div class="prop-item-improved">
								<div style="display: flex; gap: 4px; align-items: center;">
									<label>Đưa lên trên/Đẩy xuống dưới</label>
									<input type="number" v-model.number="selectedElement.zIndex" @input="updateJson"
										style="width: 60px;" />
								</div>
							</div>
							<div class="prop-item-improved">
								<div v-if="selectedElement?.type === 'text-element'">
									<label>Xoay (deg):</label>
									<input type="number" v-model="rotationValue" @input="applyTextRotation" />
								</div>
							</div>
							<div class="prop-item-improved">
								<label>Font</label>
								<select v-model="selectedElement.style.fontFamily" @change="updateJson">
									<option v-for="font in fontOptions" :key="font" :value="font">{{ font }}</option>
								</select>
							</div>
							<div class="prop-item-improved">
								<label>Màu chữ</label>
								<input type="color" v-model="selectedElement.style.color" @input="updateJson" />
							</div>
							<div class="prop-item-improved">
								<label>Màu nền</label>
								<input type="color" v-model="selectedElement.style.backgroundColor"
									@input="updateJson" />
							</div>
							<div class="prop-item-improved">
								<label>Bo góc (px)</label>
								<input type="text" v-model="selectedElement.style.borderRadius" @input="updateJson" />
							</div>
							<div class="prop-item-improved">
								<label>Cỡ chữ (px)</label>
								<input type="number" :min="1" v-model.number="fontSizeValue" @input="applyFontSize" />
							</div>
							<div class="prop-item-improved">
								<label>Khoảng cách dòng</label>
								<input type="number" step="0.1" v-model="selectedElement.style.lineHeight"
									@input="updateJson" />
							</div>
							<div class="prop-item-improved">
								<label>Đậm</label>
								<select v-model="selectedElement.style.fontWeight" @change="updateJson">
									<option v-for="weight in fontWeightOptions" :key="weight.value"
										:value="weight.value">
										{{ weight.text }}
									</option>
								</select>
							</div>
							<div class="prop-item-improved">
								<label>In nghiêng</label>
								<select :value="selectedElement.style.fontStyle || 'normal'"
									@change="selectedElement.style.fontStyle = $event.target.value; updateJson()">
									<option v-for="style in fontStyleOptions" :key="style.value" :value="style.value">
										{{ style.text }}
									</option>
								</select>
							</div>

							<!-- Padding controls -->
							<div class="prop-item-improved">
								<label>Padding (px)</label>
								<input type="text" :value="selectedElement.style.padding?.replaceAll('px','').trim()"
									@input="applyUnit('padding', $event)" placeholder="10 hoặc 10 15 10 15" />
							</div>
							<div class="prop-item-improved">
								<label>Padding trên (px)</label>
								<input type="text" :value="selectedElement.style.paddingTop?.replaceAll('px','').trim()"
									@input="applyUnit('paddingTop', $event)" />
							</div>
							<div class="prop-item-improved">
								<label>Padding dưới (px)</label>
								<input type="text"
									:value="selectedElement.style.paddingBottom?.replaceAll('px','').trim()"
									@input="applyUnit('paddingBottom', $event)" />
							</div>
							<div class="prop-item-improved">
								<label>Padding trái (px)</label>
								<input type="text"
									:value="selectedElement.style.paddingLeft?.replaceAll('px','').trim()"
									@input="applyUnit('paddingLeft', $event)" />
							</div>
							<div class="prop-item-improved">
								<label>Padding phải (px)</label>
								<input type="text"
									:value="selectedElement.style.paddingRight?.replaceAll('px','').trim()"
									@input="applyUnit('paddingRight', $event)" />
							</div>

							<!-- Border controls -->
							<div class="prop-item-improved">
								<label>Độ dày viền (px)</label>
								<input type="text"
									:value="selectedElement.style.borderWidth?.replaceAll('px','').trim()"
									@input="applyUnit('borderWidth', $event)" />
							</div>
							<div class="prop-item-improved">
								<label>Kiểu viền</label>
								<select v-model="selectedElement.style.borderStyle" @change="updateJson">
									<option value="none">Không</option>
									<option value="solid">Liền</option>
									<option value="dashed">Gạch nối</option>
									<option value="dotted">Chấm</option>
									<option value="double">Đôi</option>
									<option value="groove">Rãnh</option>
									<option value="ridge">Nổi</option>
									<option value="inset">Lõm</option>
									<option value="outset">Lồi</option>
								</select>
							</div>
							<div class="prop-item-improved">
								<label>Màu viền</label>
								<input type="color" v-model="selectedElement.style.borderColor" @input="updateJson" />
							</div>

							<!-- Text decoration (line style) -->
							<div class="prop-item-improved">
								<label>Kiểu gạch chân</label>
								<select v-model="selectedElement.style.textDecoration" @change="updateJson">
									<option value="none">Không</option>
									<option value="underline">Gạch chân</option>
									<option value="overline">Gạch trên</option>
									<option value="line-through">Gạch ngang</option>
									<option value="underline overline">Gạch chân + trên</option>
								</select>
							</div>
						</div>

						<!-- Image & Icon Element Properties -->
						<div v-if="selectedElement && (selectedElement.type === 'image-element' || ['best-seller', 'signature', 'het-mon'].includes(selectedElement.role))"
							class="properties-panel-improved">
							<!-- Toggle Aspect Ratio -->
							<div class="prop-item-improved d-flex align-center">
								<v-checkbox class="ButtonCheck" v-model="keepAspectRatio"
									label="Giữ tỉ lệ ảnh (khóa chiều rộng/chiều cao)" dense hide-details />
							</div>
							<!-- Rộng (px) -->
							<div class="prop-item-improved">
								<label>Rộng (px)</label>
								<input type="number" v-model.number="selectedElement.width" @input="onWidthChange" />
							</div>

							<!-- Cao (px) -->
							<div class="prop-item-improved">
								<label>Cao (px)</label>
								<input type="number" v-model.number="selectedElement.height" @input="onHeightChange" />
							</div>
							<div class="prop-item-improved">
								<label>Bo góc (px)</label>
								<input type="text" v-model="selectedElement.style.borderRadius" @input="updateJson" />
							</div>
							<div class="prop-item-improved">
								<label>Đưa lên trên/Đẩy xuống dưới</label>
								<input type="number" v-model.number="selectedElement.zIndex" @input="updateJson" />
							</div>
							<div class="prop-item-improved">
								<label>Xoay (độ)</label>
								<input type="number" v-model.number="selectedElement.rotation" @input="updateJson" />
							</div>
						</div>
						<!-- ✅ Group Properties: quản lý nhiều 'Nội dung' trong group -->
						<div v-if="selectedElement && selectedElement.type === 'group'"
							class="properties-panel-improved">
							<div class="prop-item-improved d-flex align-center justify-space-between" style="gap:8px">
								<label style="margin:0">Nội dung</label>
								<button class="json-btn-improved" @click="addContentToGroup(selectedElement.id)">
									<i class="mdi mdi-plus"></i> Thêm nội dung
								</button>
							</div>
							<!-- Nút căn chỉnh nội dung -->
							<div class="prop-item-improved d-flex align-center justify-space-between" style="gap:8px">
								<label style="margin:0">Căn chỉnh nội dung</label>
								<div style="display:flex; gap:6px">
									<button class="json-btn-improved" @click="alignTextChildren('vertical')">
										<i class="mdi mdi-format-vertical-align-center"></i> Căn dọc
									</button>
									<button class="json-btn-improved" @click="alignTextChildren('horizontal')">
										<i class="mdi mdi-format-horizontal-align-center"></i> Căn ngang
									</button>
								</div>
							</div>
							<!-- Danh sách tất cả text children (trừ stt/price/page-number) -->
							<div v-for="(t, idx) in getTextChildren(selectedElement)" :key="t.id"
								class="prop-item-improved"
								style="border:1px solid #eee; border-radius:8px; padding:8px; margin-bottom:8px;">
								<div class="d-flex align-center justify-space-between" style="margin-bottom:6px;">
									<strong>Nội dung #{{ idx + 1 }}</strong>
									<div style="display:flex; gap:6px">
										<button class="json-btn-improved" @click="selectElement(t)"
											title="Chọn phần tử này">
											<i class="mdi mdi-cursor-default-click-outline"></i>
										</button>
										<button class="json-btn-improved" style="background:#ffebee;color:#c62828"
											@click="deleteChildElement(selectedElement, t)" title="Xoá nội dung này">
											<i class="mdi mdi-delete-outline"></i>
										</button>
									</div>
								</div>

								<v-textarea outlined rows="3" v-model="t.content" @input="updateJson" />
								<div class="d-flex" style="gap:8px; margin-top:6px">
									<input type="number" class="form-input" style="width:90px"
										v-model.number="t.style.fontSize" @input="updateJson" placeholder="Font px">
									<input type="color" v-model="t.style.color" @input="updateJson" title="Màu chữ" />
									<select v-model="t.style.textAlign" @change="updateJson">
										<option value="left">Trái</option>
										<option value="center">Giữa</option>
										<option value="right">Phải</option>
										<option value="justify">Căn đều</option>
									</select>
								</div>
							</div>
						</div>
					</div>

					<!-- No Selection -->
					<div v-else class="no-selection-placeholder-improved">
						Chọn một phần tử để chỉnh sửa.
					</div>
				</div>
			</div>

			<!-- JSON Editor Combined Section -->
			<div v-if="showJsonEditor" class="json-section-improved" style="border-top: 1px solid var(--border-color);">
				<h4>
					<i class="mdi mdi-code-json"></i>
					Chỉnh sửa / Xem / Xuất JSON
				</h4>

				<v-textarea v-model="editableJson" rows="12" outlined class="json-editor-textarea"
					style="font-family: monospace;">
				</v-textarea>

				<div class="json-buttons">
					<button @click="applyEditedJson" class="json-btn-improved">
						<i class="mdi mdi-content-save-edit"></i> Áp dụng JSON
					</button>
					<button @click="copyExportedJson" class="json-btn-improved">
						<i class="mdi mdi-content-copy"></i> Sao chép JSON hiện tại
					</button>
					<button @click="exportJson" class="json-btn-improved">
						<i class="mdi mdi-download"></i> Xuất JSON
					</button>
				</div>
			</div>
		</div>

		<!-- FOOTER - PAGE NAVIGATION FIXED -->
		<div class="page-navigation-improved">
			<!-- Left Arrow -->
			<button class="page-nav-arrow-improved" @click="scrollPagesLeft" :disabled="false" title="Scroll trái">
				<i class="mdi mdi-chevron-left"></i>
			</button>

			<!-- Page Tabs Container -->
			<div class="page-tabs-container-improved">
				<div class="page-tabs-improved" ref="pageTabs">
					<div v-for="(page, index) in pages" :key="page.id" class="page-tab-improved" :class="{
						active: index === currentPageIndex,
						editing: editingPageIndex === index
					}" @click="selectPage(index)" @dblclick="startEditPageName(index)" draggable="true"
						@dragstart="startPageDrag(index, $event)" @dragover="onPageDragOver(index, $event)"
						@drop="onPageDrop(index, $event)" @dragend="endPageDrag" @dragleave="onPageDragLeave">
						<i class="mdi mdi-file-document-outline"></i>

						<!-- Display Mode -->
						<span v-if="editingPageIndex !== index" class="page-name-display">
							{{ getPageDisplayName(page, index) }}
						</span>

						<!-- Edit Mode -->
						<input v-if="editingPageIndex === index" ref="pageNameInput" class="page-name-input"
							:value="page.name || getDefaultPageName(page, index)"
							@input="updatePageName(index, $event.target.value)" @blur="finishEditPageName(index)"
							@keydown.enter="finishEditPageName(index)" @keydown.esc="cancelEditPageName(index)" />

						<!-- Close Button -->
						<button class="page-close-btn-improved" @click.stop="confirmDeletePage(index)"
							title="Xóa trang">
							×
						</button>
					</div>
				</div>
			</div>

			<!-- Right Arrow -->
			<button class="page-nav-arrow-improved" @click="scrollPagesRight" :disabled="false" title="Scroll phải">
				<i class="mdi mdi-chevron-right"></i>
			</button>

			<!-- Add Page Button -->
			<button class="add-page-btn-improved" @click="addNewPage">
				<i class="mdi mdi-plus"></i>
				<span>Thêm trang</span>
			</button>
			<button class="add-page-btn-improved" @click="addPageNumbersToAllPages">
				<i class="mdi mdi-reload"></i>
				Thêm lại số trang
			</button>
			<button class="add-page-btn-improved" @click="removeAllPageNumbers" style="color: #c62828;">
				<i class="mdi mdi-numeric-off"></i>
				Xoá số trang
			</button>
			<!-- ZOOM CONTROL -->
			<div class="zoom-controls d-flex align-center" style="margin-left:16px; width:260px;">
				<v-btn icon small @click="zoomOut">
					<v-icon>mdi-minus</v-icon>
				</v-btn>

				<v-slider v-model="zoomLevel" min="0.2" max="3" step="0.1" class="flex-grow-1 mx-2" hide-details />

				<v-btn icon small @click="zoomIn">
					<v-icon>mdi-plus</v-icon>
				</v-btn>

				<span style="min-width:45px; text-align:center; cursor:pointer;" @click="resetZoom">
					{{ Math.round(zoomLevel * 100) }}%
				</span>
			</div>
		</div>

		<!-- DELETE CONFIRMATION DIALOG -->
		<div v-if="showDeleteConfirm" class="delete-confirm-overlay" @click="cancelDeletePage">
			<div class="delete-confirm-dialog" @click.stop>
				<h3>Xác nhận xóa trang</h3>
				<p>
					Bạn có chắc muốn xóa trang
					<strong>"{{ pageToDelete?.name }}"</strong>?
					<br>
					Hành động này không thể hoàn tác.
				</p>
				<div class="delete-confirm-actions">
					<button class="delete-confirm-btn cancel" @click="cancelDeletePage">
						Hủy
					</button>
					<button class="delete-confirm-btn delete" @click="executeDeletePage">
						Xóa
					</button>
				</div>
			</div>
		</div>
	</div>
</template>
<script>
	export default {
		props: {
			menuItems: { type: Array, default: () => [] },
			loading: { type: Boolean, default: false },
			menubookLoading: { type: Boolean, default: false },
			loadingMessage: { type: String, default: '' },
			menubookData: { type: Array, default: null },
			currentMenubookInfo: { type: Object, default: () => ({}) },
			uiState: { type: Object, default: () => ({}) },
			templateList: { type: Array, default: null }
		},
	
		data() {
			return {
				filelist: [],
				fileEX: {
					"max_file_size": "100mb",
					"mime_types": [
						{
							"title": "All files",
							"extensions": "jpg,png"
						}
					]
				},
				keepAspectRatio: true,
				rotationValue: 0,
				showJsonEditor: false,
				hasInitialized: false,
				editableJson: '',
				isSaved: false,
				originalAspectRatio: 1,
				expandedPanels: [0, 1],
				isLoading: true,
				displayItems: [],
				availableTemplates: [],
				importFile: null,
				draggedPageIndex: null,
				dragOverIndex: null,
				zoomLevel: 1,
				fontSizeValue: null,
	
				// ✅ Sidebar collapse state
				sidebarCollapsed: false,
	
				// ✅ Page editing state
				editingPageIndex: -1, // Index của page đang được edit (-1 = không edit)
				originalPageName: '', // Lưu tên gốc để restore khi ESC
	
				// ✅ Delete confirmation
				showDeleteConfirm: false,
				pageToDelete: null,
				pageIndexToDelete: -1,
	
				// Canvas data
				pages: [{ id: Date.now(), type: 'Desktop', name: 'Trang bìa', background: null, elements: [] }],
				currentPageIndex: 0,
	
				// Page dimensions
				pageDimensions: {
					Desktop: { width: 529, height: 707 },
					Tablet: { width: 500, height: 417 },
					Mobile: { width: 214, height: 300 },
					// Custom: { width: 847, height: 707 }
				},
	
				// Assets
				imageAssets: [],
				backgroundAssets: [],
	
				// UI state
				exportedJson: '',
				draggedData: null,
				selectedElement: null,
				draggingElement: null,
				dragOffset: { x: 0, y: 0 },
				dragType: null,
	
				// History management
				history: [],
				historyIndex: -1,
				searchQuery: '',
				copiedElement: null,
				autoItemIndex: 1,
	
				// MenuBook info
				menuBookId: null,
				originalMenuInfo: null,
	
				// Form options
				fontOptions: ['Inter', 'Verdana', 'Times New Roman', 'Roboto', 'Open Sans'],
				fontWeightOptions: [
					// { text: 'Mỏng', value: '300' },
					{ text: 'Thường', value: '400' },
					{ text: 'Đậm', value: '700' },
					{ text: 'Rất đậm', value: '900' }
				],
				fontStyleOptions: [
					{ text: 'Thường', value: 'normal' },
					{ text: 'In nghiêng', value: 'italic' }
				],
				textAlignOptions: [
					{ text: 'Trái', value: 'left' },
					{ text: 'Giữa', value: 'center' },
					{ text: 'Phải', value: 'right' },
					{ text: 'Căn đều', value: 'justify' }
				],
				selectedIds: [],
	
			}
		},
	
		computed: {
			currentPage() {
				return this.pages?.[this.currentPageIndex] || null;
			},
	
			filteredItems() {
				const querySlug = toSlug(this.searchQuery || "");
				const dataFilter = this.displayItems.filter(item => {
					const nameSlug = toSlug(item.name || "");
					return nameSlug.includes(querySlug) && !item.used;
				});
				return dataFilter ?? [];
			},
		},
	
		watch: {
	
			exportedJson(newVal) {
				this.editableJson = newVal;
			},
			loading(newValue) {
				this.isLoading = newValue;
			},
	
			selectedElement: {
				handler(val) {
					if (!val) return;
	
					// ✅ Giữ logic cho ảnh gốc
					if (val.type === 'image-element' && val.width && val.height) {
						const aspect = val.width / val.height;
						this.originalAspectRatio = aspect;
						val.originalAspectRatio = aspect;
					}
	
					// ✅ Bổ sung logic cho text-element (tự parse cỡ chữ)
					if (val.type === 'text-element') {
						const rawSize = val.style?.fontSize || '16px';
						this.fontSizeValue = parseInt(rawSize); // bỏ px
					}
				},
				immediate: true,
			},
	
			menuItems(newItems) {
				if (newItems && newItems.length > 1 && Array.isArray(newItems[1])) {
					this.displayItems = newItems[1].map(item => ({
						...item,
						id: item.SanPhamID,
						id_SanPham: item.SanPhamID,
						name: item.TenSanPham,
						price: new Intl.NumberFormat('vi-VN').format(item.GiaBan_CuaHang) + 'đ',
						image: item.AnhSanPham_Url,
						stt: item.MaSoSanPham,
						MaSoSanPham: item.MaSoSanPham || '',
						Is_BestSeller: item.Is_BestSeller || false,
						Is_Signature: item.Is_Signature || false,
						Is_HetMon: item.Is_HetMon || false,
						TenNgan: item.TenNgan || '',
						used: false
					}));
				} else {
					this.displayItems = [];
				}
			},
	
			menubookData: {
				handler(newData) {
					if (newData && !this.hasInitialized) {
						this.hasInitialized = true; // ✅ Chỉ cho phép chạy 1 lần
						this.processMenuBookData();
					}
				},
				immediate: true
			},
	
			'uiState.trigger_process_menubook': {
				handler(newValue) {
					if (newValue && this.menubookData) {
						this.processMenuBookData();
						this.$nextTick(() => {
							if (vueData.ui_state) {
								vueData.ui_state.trigger_process_menubook = false;
							}
						});
					}
				},
				immediate: true
			},
	
			// ✅ Auto scroll to active page
			currentPageIndex() {
				this.scrollToActivePage();
			},
		},
	
		methods: {
			applyUnit(styleProp, event) {
				if (!this.selectedElement || !this.selectedElement.style) return;
				const value = event.target.value.trim();
	
				// Cho phép giá trị rỗng hoặc nhiều số cách nhau bằng khoảng trắng
				if (!value) {
					this.selectedElement.style[styleProp] = '';
					this.updateJson();
					return;
				}
	
				// Nếu người dùng nhập nhiều giá trị (ví dụ "10 15 10 15")
				const formatted = value
					.split(/\s+/)
					.map(v => (v.endsWith('px') ? v : `${v}px`))
					.join(' ');
	
				this.selectedElement.style[styleProp] = formatted;
				this.updateJson();
			},
	
			handleGlobalClick(e) {
				const canvas = this.$refs.canvas;
				if (!canvas) return;
	
				const rightSidebar = document.querySelector('.right-sidebar-improved');
				const leftSidebar = document.querySelector('.left-sidebar-improved');
	
				// Nếu click vào sidebar trái hoặc phải thì KHÔNG bỏ chọn
				if ((rightSidebar && rightSidebar.contains(e.target)) ||
					(leftSidebar && leftSidebar.contains(e.target))) {
					return;
				}
	
				// Nếu click không nằm trong canvas → bỏ chọn
				if (!canvas.contains(e.target)) {
					this.clearSelection();
					return;
				}
	
				// Nếu click bên trong canvas nhưng không vào phần tử nào → bỏ chọn
				const clickedOnElement = e.target.closest('.canvas-element-improved, .group-child-improved, .canvas - element - group - improved');
				if (!clickedOnElement) {
					this.clearSelection();
				}
			},
			isAnyChildSelected(group) {
				if (!group || !Array.isArray(group.children)) return false;
				return group.children.some(child => this.isSelectedId(child.id));
			},
			applyFontSize() {
				if (!this.selectedElement || this.selectedElement.type !== 'text-element') return;
				this.selectedElement.style.fontSize = `${this.fontSizeValue}px`;
				this.updateJson();
			},
	
			alignTextChildren(direction) {
				const group = this.selectedElement;
				if (!group || group.type !== 'group' || !Array.isArray(group.children)) {
					this.showNotification('Không có group hợp lệ để căn chỉnh', 'warning');
					return;
				}
	
				// Lọc text-element hợp lệ
				const texts = group.children.filter(c =>
					c.type === 'text-element' &&
					(!c.role || !['stt', 'page-number'].includes(c.role))
				);
	
				if (!texts || texts.length < 2) { this.showNotification('Cần ít nhất 2 nội dung text để căn chỉnh', 'info'); return; }
				if (direction === 'vertical') { // Căn dọc: cùng X (theo phần tử đầu tiên) 
					let baseX = 0; if (texts[0] && typeof
						texts[0].relative_x === 'number') { baseX = texts[0].relative_x; } console.log('Căn dọc - baseX:', baseX, texts.map(t =>
							t.relative_x));
	
					texts.forEach(t => {
						t.relative_x = baseX;
					});
	
				} else if (direction === 'horizontal') {
					// Căn ngang: cùng Y (theo phần tử đầu tiên)
					let baseY = 0;
					if (texts[0] && typeof texts[0].relative_y === 'number') {
						baseY = texts[0].relative_y;
					}
	
					console.log('Căn ngang - baseY:', baseY, texts.map(t => t.relative_y));
	
					texts.forEach(t => {
						t.relative_y = baseY;
					});
	
				} else if (direction === 'vertical-center') {
					// Căn giữa dọc theo trung tâm khung group
					const minX = Math.min(...texts.map(t => t.relative_x || 0));
					const maxX = Math.max(...texts.map(t => (t.relative_x || 0) + (parseInt(t.style?.width) || 0)));
					const mid = (minX + maxX) / 2;
	
					texts.forEach(t => {
						const width = parseInt(t.style?.width) || 0;
						t.relative_x = Math.round(mid - width / 2);
					});
				}
	
				this.updateJson();
				this.showNotification('Đã căn chỉnh các nội dung', 'success');
			},
			getTextChildren(group) {
				if (!group || !Array.isArray(group.children)) return [];
				return group.children.filter(c =>
					c.type === 'text-element' &&
					(!c.role || !['stt', 'price', 'page-number'].includes(c.role))
				);
			},
			getParentGroupId(el) {
				if (!el || !this.currentPage) return null;
				const group = this.currentPage.elements.find(g =>
					g.type === 'group' && Array.isArray(g.children) && g.children.some(c => String(c.id) === String(el.id))
				);
				return group ? group.id : null;
			},
			// ✅ Thêm 1 text child mới vào group, auto sắp vị trí bên dưới cái cuối
			addContentToGroup(groupId) {
				if (!groupId || !this.currentPage) {
					this.showNotification('Không xác định được Group để thêm nội dung', 'warning');
					return;
				}
				const group = this.currentPage.elements.find(g => g.id === groupId && g.type === 'group');
				if (!group) {
					this.showNotification('Group không tồn tại', 'error');
					return;
				}
	
				const texts = this.getTextChildren(group);
	
				// Tính vị trí mặc định: đặt bên phải ảnh hoặc dưới dòng text cuối
				let defaultX = 100; // gần khu vực tên món
				let defaultY = 25; // gần khu vực tên món
				if (texts.length > 0) {
					const last = texts[texts.length - 1];
					const lastLineHeight = parseInt(last.style?.fontSize || 16) + 8; // spacing
					defaultX = last.relative_x;
					defaultY = last.relative_y + lastLineHeight;
				}
	
				const newId = Date.now() + Math.random();
				const newText = {
					id: newId,
					groupId: group.id,
					type: 'text-element',
					role: 'content', // đánh dấu là nội dung
					relative_x: defaultX,
					relative_y: defaultY,
					zIndex: 1,
					content: 'Nội dung mới',
					style: {
						fontSize: '16', // số thuần cho input number ở panel
						fontWeight: '400',
						color: '#333333',
						fontFamily: 'Inter',
						backgroundColor: 'transparent',
						textAlign: 'left',
						lineHeight: '1.2'
					}
				};
	
				group.children = group.children || [];
				group.children.push(newText);
	
				// Chọn ngay text mới để người dùng chỉnh tiếp
				this.selectedElement = newText;
				if (!this.selectedIds.includes(String(newId))) {
					this.selectedIds = [String(newId)];
				}
	
				this.updateJson();
				this.showNotification('Đã thêm nội dung mới vào group', 'success');
			},
			zoomIn() {
				this.zoomLevel = Math.min(this.zoomLevel + 0.1, 3);
			},
			zoomOut() {
				this.zoomLevel = Math.max(this.zoomLevel - 0.1, 0.2);
			},
			resetZoom() {
				this.zoomLevel = 1;
			},
	
	
			isSelectedId(id) {
				return this.selectedIds.includes(String(id));
			},
			clearSelection() {
				this.selectedIds = [];
				this.selectedElement = null;
			},
	
			/** Gọi khi muốn chọn 1 phần tử (element hoặc child).
			* - Giữ Ctrl/Cmd để toggle chọn/bỏ chọn mà không mất các lựa chọn khác
			* - Nếu không giữ, sẽ chỉ chọn 1 phần tử (deselect các cái còn lại)
			*/
			selectAny(el, event = null) {
				const multiKey = event && (event.ctrlKey || event.metaKey);
				const id = String(el.id);
	
				if (multiKey) {
					if (this.isSelectedId(id)) {
						this.selectedIds = this.selectedIds.filter(x => x !== id);
						// nếu bỏ phần tử đang là selectedElement thì cập nhật lại
						if (this.selectedElement && String(this.selectedElement.id) === id) {
							this.selectedElement = null;
						}
					} else {
						this.selectedIds = [...this.selectedIds, id];
						this.selectedElement = el; // để panel properties còn hiển thị dựa vào 1 phần tử “trọng tâm”
					}
				} else {
					this.selectedIds = [id];
					this.selectedElement = el;
				}
			},
	
			/** Xoá tất cả phần tử đã chọn (trên trang hiện tại) */
			deleteSelected() {
				if (!this.currentPage || this.selectedIds.length === 0) return;
	
				const selectedSet = new Set(this.selectedIds.map(String));
				const newElements = [];
	
				for (const el of this.currentPage.elements) {
					// Nếu group bị chọn → xoá nguyên group
					if (selectedSet.has(String(el.id))) {
						// hoàn tác “used” nếu là group từ menu item
						if (el.type === 'group' && el.id_SanPham) {
							const item = this.displayItems.find(it => it.id_SanPham === el.id_SanPham);
							if (item) item.used = false;
						}
						continue; // skip push => xoá
					}
	
					// Nếu không phải group → giữ nguyên (trừ khi chính nó đã được chọn)
					if (el.type !== 'group') {
						if (!selectedSet.has(String(el.id))) {
							newElements.push(el);
						}
						continue;
					}
	
					// Group không bị chọn: lọc con
					if (Array.isArray(el.children) && el.children.length) {
						el.children = el.children.filter(ch => !selectedSet.has(String(ch.id)));
					}
					newElements.push(el);
				}
	
				this.currentPage.elements = newElements;
	
				// dọn selection
				this.clearSelection();
				this.updateJson();
				this.showNotification('Đã xoá các phần tử đã chọn', 'success');
			},
			startResize(el, event, position) {
				// Ngăn sự kiện lan ra các nhóm khác
				event.stopPropagation();
				event.preventDefault();
	
				this.resizingElement = el;
				this.resizePosition = position;
				this.startX = event.clientX;
				this.startY = event.clientY;
				this.startWidth = el.width;
				this.startHeight = el.height;
				this.startLeft = el.x;
				this.startTop = el.y;
	
				// Gắn listener toàn cục
				document.addEventListener('mousemove', this.onResizing);
				document.addEventListener('mouseup', this.stopResize);
			},
	
			onResizing(event) {
				if (!this.resizingElement) return;
	
				// Tính toán theo tỉ lệ zoom hiện tại
				const dx = (event.clientX - this.startX) / this.zoomLevel;
				const dy = (event.clientY - this.startY) / this.zoomLevel;
	
				const el = this.resizingElement;
	
				// Kéo phải
				if (this.resizePosition.includes('e')) {
					el.width = Math.max(10, this.startWidth + dx);
				}
				// Kéo xuống
				if (this.resizePosition.includes('s')) {
					el.height = Math.max(10, this.startHeight + dy);
				}
				// Kéo trái
				if (this.resizePosition.includes('w')) {
					el.width = Math.max(10, this.startWidth - dx);
					el.x = this.startLeft + dx;
				}
				// Kéo lên
				if (this.resizePosition.includes('n')) {
					el.height = Math.max(10, this.startHeight - dy);
					el.y = this.startTop + dy;
				}
	
				this.updateJson();
			},
			stopResize() {
				document.removeEventListener('mousemove', this.onResizing);
				document.removeEventListener('mouseup', this.stopResize);
				this.resizingElement = null;
			},
			increaseZIndex() {
				if (!this.selectedElement) return;
				this.selectedElement.zIndex = (this.selectedElement.zIndex || 1) + 1;
				this.updateJson();
			},
			decreaseZIndex() {
				if (!this.selectedElement) return;
				this.selectedElement.zIndex = (this.selectedElement.zIndex || 1) - 1;
				this.updateJson();
			},
			getAllElements() {
				let all = [];
				this.pages.forEach(page => {
					all = all.concat(page.elements || []);
					page.elements?.forEach(el => {
						if (el.type === 'group') {
							all = all.concat(el.children || []);
						}
					});
				});
				return all;
			},
	
			deleteChildElement(parentGroup, child) {
				if (!parentGroup || !Array.isArray(parentGroup.children) || !child) return;
	
				// Nếu là icon động thì tắt flag trong group
				if (child.role === 'best-seller') parentGroup.Is_BestSeller = false;
				if (child.role === 'signature') parentGroup.Is_Signature = false;
				if (child.role === 'het-mon') parentGroup.Is_HetMon = false;
	
				parentGroup.children = parentGroup.children.filter(c => String(c.id) !== String(child.id));
	
				if (this.selectedElement?.id === child.id) {
					this.selectedElement = null;
				}
	
				this.updateJson();
			},
	
			applyTextRotation() {
				if (this.selectedElement?.type === 'text-element') {
					this.selectedElement.style.transform = `rotate(${this.rotationValue}deg)`;
					this.updateJson();
				}
			},
	
			formatPrice(val) {
				const num = Number(val);
				if (isNaN(num)) return val; // fallback nếu không phải số
				return new Intl.NumberFormat('vi-VN', {
					style: 'currency',
					currency: 'VND',
					minimumFractionDigits: 0
				}).format(num);
			},
	
			addPageNumbersToAllPages() {
				this.pages.forEach((page, index) => {
					const hasNumber = page.elements?.some(el =>
						el.type === 'group' &&
						el.children?.some(child => child.role === 'page-number')
					);
	
					if (!hasNumber) {
						const groupId = Date.now() + Math.random();
						const numberElement = {
							id: groupId,
							type: "group",
							name: "Page number",
							isAutoPageNumber: true,
							x: 443,
							y: 22,
							width: 50,
							height: 50,
							children: [
								{
									id: Date.now() + 100,
									groupId: groupId,
									type: "text-element",
									role: "page-number",
									relative_x: 20,
									relative_y: 10,
									zIndex: 1,
									content: `${index + 1}`,
									style: {
										fontSize: "14px",
										color: "#333",
										fontFamily: "Inter",
										textAlign: "center",
										backgroundColor: "transparent"
									}
								}
							]
						};
						page.elements.unshift(numberElement);
					}
				});
				this.updateJson();
			},
	
			removeAllPageNumbers() {
				let removedCount = 0;
				this.pages.forEach(page => {
					const before = page.elements.length;
					page.elements = (page.elements || []).filter(el =>
						!(el.type === 'group' && el.isAutoPageNumber === true)
					);
					removedCount += before - page.elements.length;
				});
	
				this.updateJson();
	
				if (removedCount > 0) {
					this.showNotification(`Đã xoá ${removedCount} số trang`, 'success');
				} else {
					this.showNotification('Không tìm thấy số trang nào để xoá', 'info');
				}
			},
	
			deleteIMG(HinhAnhQuangCaoID) {
				confirm({
					title: 'Bạn có chắc muốn xóa ảnh này không?',
					action: () => {
						ajaxCALL("/eorder/HinhAnhQuangCao_Delete", {
							HinhAnhQuangCaoID: HinhAnhQuangCaoID
						}, (res) => {
							this.loadAssets();
							this.loadAssets_bg();
						});
					}
				});
			},
	
			ensureDynamicIcons(group) {
				if (!group || group.type !== 'group') return;
	
				// Giữ lại các icon đã chỉnh vị trí (customPositioned = true)
				group.children = (group.children || []).filter(child =>
					!child.role || !['best-seller', 'signature', 'het-mon'].includes(child.role) || child.customPositioned
				);
	
				const addIconIfNotExist = (role, src, x, y) => {
					if (!group.children.some(c => c.role === role)) {
						group.children.push({
							id: Date.now() + Math.random(),
							groupId: group.id,
							type: 'image-element',
							role: role,
							relative_x: x,
							relative_y: y,
							width: 55,
							height: 50,
							src: src,
							style: {},
							customPositioned: false
						});
					}
				};
	
				if (group.Is_BestSeller) {
					addIconIfNotExist('best-seller', '/_cdn/zen-eorder/trang-thai-icon/ic-best-seller.png', 200, -30);
				}
				if (group.Is_Signature) {
					addIconIfNotExist('signature', '/_cdn/zen-eorder/trang-thai-icon/ic-signature.png', 193, -30);
				}
				if (group.Is_HetMon) {
					addIconIfNotExist('het-mon', '/_cdn/zen-eorder/trang-thai-icon/ic-het-mon.png', 185, -30);
				}
			},
	
			updateAllPageNumbers() {
				this.pages.forEach((page, index) => {
					page.elements?.forEach(el => {
						if (el.type === 'group') {
							el.children?.forEach(child => {
								if (child.role === 'page-number') {
									child.content = `${index + 1}`;
								}
							});
						}
					});
				});
				this.updateJson();
			},
	
			deleteSelectedElement() {
				if (!this.selectedElement) return;
	
				// Nếu là group và có id_SanPham → enable lại món
				if (this.selectedElement.type === 'group' && this.selectedElement.id_SanPham) {
					const item = this.displayItems.find(item => item.id_SanPham === this.selectedElement.id_SanPham);
					if (item) item.used = false;
				}
	
				// Xoá phần tử khỏi danh sách
				const index = this.elements.findIndex(e => e.id === this.selectedElement.id);
				if (index !== -1) {
					this.elements.splice(index, 1);
				}
	
				this.selectedElement = null;
				this.updateJson();
			},
			handleArrowKey(e) {
				if (this.selectedElement && this.selectedElement.role && ['best-seller', 'signature',
					'het-mon'].includes(this.selectedElement.role)) {
					this.selectedElement.customPositioned = true; // khi user chỉnh bằng phím cũng lưu lại trạng thái đã chỉnh
				}
	
				if (!this.selectedElement || e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
	
				let step = e.shiftKey ? 10 : 1; // nhấn Shift để tăng khoảng di chuyển
	
				// Nếu là element con của group
				if (this.selectedElement.groupId) {
					const group = this.currentPage.elements.find(g => g.id === this.selectedElement.groupId);
					if (!group) return;
	
					switch (e.key) {
						case 'ArrowUp':
							this.selectedElement.relative_y -= step;
							break;
						case 'ArrowDown':
							this.selectedElement.relative_y += step;
							break;
						case 'ArrowLeft':
							this.selectedElement.relative_x -= step;
							break;
						case 'ArrowRight':
							this.selectedElement.relative_x += step;
							break;
						default:
							return;
					}
				} else {
					// Nếu là element chính (image/group)
					switch (e.key) {
						case 'ArrowUp':
							this.selectedElement.y -= step;
							break;
						case 'ArrowDown':
							this.selectedElement.y += step;
							break;
						case 'ArrowLeft':
							this.selectedElement.x -= step;
							break;
						case 'ArrowRight':
							this.selectedElement.x += step;
							break;
						default:
							return;
					}
				}
	
				e.preventDefault();
				this.updateJson();
			},
	
			applyEditedJson() {
				try {
					const parsed = JSON.parse(this.editableJson);
					this.reconstructCanvas(parsed);
					this.showNotification("Đã cập nhật từ JSON thành công", "success");
				} catch (e) {
					this.showNotification("Lỗi JSON: " + e.message, "error");
				}
			},
			copyExportedJson() {
				navigator.clipboard.writeText(this.exportedJson).then(() => {
					this.showNotification("Đã sao chép JSON", "success");
				}).catch(err => {
					console.error(err);
					this.showNotification("Không thể sao chép JSON", "error");
				});
			},
			onWidthChange() {
				if (this.selectedElement) {
					// Nếu giữ tỉ lệ và element có lưu originalAspectRatio
					if (this.keepAspectRatio && this.selectedElement.originalAspectRatio) {
						this.selectedElement.height = Math.round(
							this.selectedElement.width / this.selectedElement.originalAspectRatio
						);
					}
					this.updateJson();
				}
			},
	
			onHeightChange() {
				if (this.selectedElement) {
					if (this.keepAspectRatio && this.selectedElement.originalAspectRatio) {
						this.selectedElement.width = Math.round(
							this.selectedElement.height * this.selectedElement.originalAspectRatio
						);
					}
					this.updateJson();
				}
			},
	
			// ========================
			// ✅ SIDEBAR COLLAPSE METHODS
			// ========================
	
			/**
			 * Toggle sidebar collapse state
			 */
			toggleSidebar() {
				// Kết thúc edit page name nếu đang edit
				if (this.editingPageIndex !== -1) {
					this.finishEditPageName(this.editingPageIndex);
				}
	
				this.sidebarCollapsed = !this.sidebarCollapsed;
				localStorage.setItem('sidebar-collapsed', this.sidebarCollapsed);
	
				this.$nextTick(() => {
					this.updateCanvasSize();
				});
			},
	
			/**
			 * Load sidebar state from localStorage
			 */
			loadSidebarState() {
				const saved = localStorage.getItem('sidebar-collapsed');
				if (saved !== null) {
					this.sidebarCollapsed = JSON.parse(saved);
				}
			},
	
			/**
			 * Update canvas size when sidebar changes
			 */
			updateCanvasSize() {
				console.log('Canvas resized due to sidebar toggle');
			},
	
			// ========================
			// ✅ DOUBLE CLICK RENAME METHODS
			// ========================
	
			/**
			 * Select page (single click)
			 */
			selectPage(index) {
				// Chỉ thay đổi page nếu không đang edit
				if (this.editingPageIndex === -1) {
					this.currentPageIndex = index;
					this.scrollToActivePage();
				}
			},
	
			/**
			 * Start editing page name (double click)
			 */
			startEditPageName(index) {
				// Kết thúc edit hiện tại nếu có
				if (this.editingPageIndex !== -1) {
					this.finishEditPageName(this.editingPageIndex);
				}
	
				// Bắt đầu edit page mới
				this.editingPageIndex = index;
				this.originalPageName = this.pages[index].name || this.getDefaultPageName(this.pages[index], index);
	
				// Focus vào input sau khi render
				this.$nextTick(() => {
					const inputs = this.$refs.pageNameInput;
					if (inputs && inputs.length > 0) {
						const input = inputs[index];
						if (input) {
							input.focus();
							input.select(); // Select all text
						}
					}
				});
			},
	
			/**
			 * Finish editing page name (blur, enter)
			 */
			finishEditPageName(index) {
				if (this.editingPageIndex === index) {
					this.editingPageIndex = -1;
					this.originalPageName = '';
					this.updateJson();
				}
			},
	
			/**
			 * Cancel editing page name (escape)
			 */
			cancelEditPageName(index) {
				if (this.editingPageIndex === index && this.pages[index]) {
					// Restore tên gốc
					this.pages[index].name = this.originalPageName;
					this.editingPageIndex = -1;
					this.originalPageName = '';
					this.updateJson();
				}
			},
	
			/**
			 * Handle click outside to finish editing
			 */
			handleClickOutside(event) {
				if (this.editingPageIndex !== -1) {
					const pageTabsContainer = this.$refs.pageTabs;
					if (pageTabsContainer && !pageTabsContainer.contains(event.target)) {
						this.finishEditPageName(this.editingPageIndex);
					}
				}
			},
	
			// ========================
			// ✅ PAGE NAVIGATION METHODS
			// ========================
	
			/**
			 * Scroll pages left
			 */
			scrollPagesLeft() {
				const container = this.$refs.pageTabs;
				if (container) {
					container.scrollBy({
						left: -120,
						behavior: 'smooth'
					});
				}
			},
	
			/**
			 * Scroll pages right  
			 */
			scrollPagesRight() {
				const container = this.$refs.pageTabs;
				if (container) {
					container.scrollBy({
						left: 120,
						behavior: 'smooth'
					});
				}
			},
	
			/**
			 * Auto scroll to active page tab
			 */
			scrollToActivePage() {
				this.$nextTick(() => {
					const container = this.$refs.pageTabs;
					const activeTab = container?.querySelector('.page-tab-improved.active');
	
					if (container && activeTab) {
						const containerRect = container.getBoundingClientRect();
						const tabRect = activeTab.getBoundingClientRect();
	
						if (tabRect.left < containerRect.left || tabRect.right > containerRect.right) {
							activeTab.scrollIntoView({
								behavior: 'smooth',
								block: 'nearest',
								inline: 'center'
							});
						}
					}
				});
			},
	
			// ========================
			// DEVICE METHODS
			// ========================
	
			/**
			 * Get device icon (Material Design Icons)
			 */
			getDeviceIcon(deviceType) {
				const icons = {
					Desktop: 'mdi mdi-monitor',
					Tablet: 'mdi mdi-tablet',
					Mobile: 'mdi mdi-cellphone',
					// Custom: 'mdi mdi-cog'
				};
				return icons[deviceType] || 'mdi mdi-monitor';
			},
	
			/**
			 * Change page type
			 */
			changePageType(newType) {
				if (this.currentPage && this.currentPage.type !== newType) {
					this.currentPage.type = newType;
					this.updateJson();
				}
			},
	
			// ========================
			// PAGE NAME METHODS
			// ========================
	
			/**
			 * Get default page name (fixed template literal issue)
			 */
			getDefaultPageName(page, index) {
				return page.type + ' ' + (index + 1);
			},
	
			/**
			 * Get display name của trang
			 */
			getPageDisplayName(page, index) {
				return page.name || this.getDefaultPageName(page, index);
			},
	
			/**
			 * Update page name (realtime khi typing)
			 */
			updatePageName(index, newName) {
				if (this.pages[index]) {
					const trimmedName = newName.trim();
					const defaultName = this.getDefaultPageName(this.pages[index], index);
	
					this.pages[index].name = trimmedName || defaultName;
					this.updateJson();
				}
			},
	
			// ========================
			// ✅ SAFE DELETE PAGE METHODS
			// ========================
	
			/**
			 * Show confirmation dialog for delete page
			 */
			confirmDeletePage(index) {
				if (this.pages.length <= 1) {
					this.showNotification('Phải có ít nhất một trang.', 'warning');
					return;
				}
	
				// Kết thúc edit nếu đang edit page bị xóa
				if (this.editingPageIndex === index) {
					this.cancelEditPageName(index);
				}
	
				this.pageToDelete = {
					name: this.pages[index].name || this.getDefaultPageName(this.pages[index], index),
					index: index
				};
				this.pageIndexToDelete = index;
				this.showDeleteConfirm = true;
			},
	
			/**
			 * Cancel delete page
			 */
			cancelDeletePage() {
				this.showDeleteConfirm = false;
				this.pageToDelete = null;
				this.pageIndexToDelete = -1;
			},
	
			/**
			 * Execute delete page
			 */
			executeDeletePage() {
				const index = this.pageIndexToDelete;
	
				if (index >= 0 && index < this.pages.length) {
					this.pages.splice(index, 1);
	
					// Adjust editing index nếu cần
					if (this.editingPageIndex > index) {
						this.editingPageIndex--;
					} else if (this.editingPageIndex === index) {
						this.editingPageIndex = -1;
					}
	
					// Adjust current page index
					if (this.currentPageIndex >= this.pages.length) {
						this.currentPageIndex = this.pages.length - 1;
					} else if (this.currentPageIndex > index) {
						this.currentPageIndex--;
					}
	
					this.updateJson();
					this.scrollToActivePage();
					this.showNotification(`Đã xóa trang "${this.pageToDelete.name}"`, 'success');
				}
				this.updateAllPageNumbers();
				// Close dialog
				this.cancelDeletePage();
			},
	
			// ========================
			// PAGE DRAG & DROP METHODS
			// ========================
	
			/**
			 * Start dragging page tab
			 */
			startPageDrag(index, event) {
				this.draggedPageIndex = index;
				event.dataTransfer.effectAllowed = 'move';
				event.dataTransfer.setData('text/html', event.target.outerHTML);
			},
	
			/**
			 * Handle drag over page tab
			 */
			onPageDragOver(index, event) {
				event.preventDefault();
				this.dragOverIndex = index;
			},
	
			/**
			 * Handle drop on page tab
			 */
			onPageDrop(index, event) {
				event.preventDefault();
				if (this.draggedPageIndex !== null && this.draggedPageIndex !== index) {
					// Reorder pages
					const draggedPage = this.pages[this.draggedPageIndex];
					this.pages.splice(this.draggedPageIndex, 1);
					this.pages.splice(index, 0, draggedPage);
	
					// Update current page index
					if (this.currentPageIndex === this.draggedPageIndex) {
						this.currentPageIndex = index;
					} else if (this.currentPageIndex > this.draggedPageIndex && this.currentPageIndex <= index) {
						this.currentPageIndex--;
					} else if (this.currentPageIndex < this.draggedPageIndex && this.currentPageIndex >= index) {
						this.currentPageIndex++;
					}
	
					this.updateJson();
					this.scrollToActivePage();
				}
				this.updateAllPageNumbers();
				this.endPageDrag();
			},
	
			/**
			 * End page drag operation
			 */
			endPageDrag() {
				this.draggedPageIndex = null;
				this.dragOverIndex = null;
			},
	
			/**
			 * Handle page drag leave
			 */
			onPageDragLeave() {
				this.dragOverIndex = null;
			},
			addNewPage() {
				const currentType = this.currentPage ? this.currentPage.type : 'Desktop';
				const insertAfterIndex = this.currentPageIndex; // vị trí trang hiện tại
	
				// Đếm số trang cùng loại để đặt tên mặc định
				const pagesOfCurrentType = this.getPagesByDeviceType(currentType);
				const pageIndex = pagesOfCurrentType.length + 1;
	
				const groupId = Date.now() + Math.random();
				const pageNumberElement = {
					id: groupId,
					type: "group",
					name: "Page number",
					x: 443,
					y: 22,
					width: 50,
					height: 50,
					children: [
						{
							id: Date.now() + 100,
							groupId: groupId,
							type: "text-element",
							role: "page-number",
							relative_x: 20,
							relative_y: 10,
							content: `${pageIndex + 1}`,
							style: {
								fontSize: "14px",
								color: "#333",
								fontFamily: "Inter",
								textAlign: "center",
								backgroundColor: "transparent"
							}
						}
					]
				};
	
				const newPage = {
					id: Date.now(),
					type: currentType,
					name: this.getDefaultPageName({ type: currentType }, pageIndex),
					background: null,
					elements: [pageNumberElement]
				};
	
				// ✅ Chèn vào ngay SAU trang đang chọn (thay vì push vào cuối)
				this.pages.splice(insertAfterIndex + 1, 0, newPage);
				this.currentPageIndex = insertAfterIndex + 1;
	
				this.updateAllPageNumbers();
				this.updateJson();
				this.scrollToActivePage();
				this.$nextTick(() => this.startEditPageName(this.currentPageIndex));
			},
	
			/**
			 * Get pages by device type
			 */
			getPagesByDeviceType(deviceType) {
				return this.pages.filter(page => page.type === deviceType);
			},
	
			setBackground(src) {
				if (this.currentPage) {
					this.currentPage.background = src;
					this.updateJson();
				}
			},
	
			/**
			 * Handle file import from input
			 */
			handleFileImport(event) {
				const file = event.target.files[0];
				if (!file) {
					this.showNotification('Không có file được chọn', 'warning');
					return;
				}
	
				// Validate file type
				if (!file.name.toLowerCase().endsWith('.json')) {
					this.showNotification('Chỉ hỗ trợ file JSON (.json)', 'warning');
					return;
				}
	
				// Validate file size (max 10MB)
				const maxSize = 10 * 1024 * 1024; // 10MB
				if (file.size > maxSize) {
					this.showNotification('File quá lớn. Kích thước tối đa là 10MB', 'warning');
					return;
				}
	
				this.loadTemplateFromFile(file);
			},
	
			/**
			 * Handle drag and drop file import
			 */
			handleFileDrop(event) {
				event.preventDefault();
				const files = event.dataTransfer.files;
	
				if (files.length === 0) {
					this.showNotification('Không có file được thả', 'warning');
					return;
				}
	
				const file = files[0];
				if (!file.name.toLowerCase().endsWith('.json')) {
					this.showNotification('Chỉ hỗ trợ file JSON (.json)', 'warning');
					return;
				}
	
				this.loadTemplateFromFile(file);
			},
	
			/**
			 * Handle drag over for file drop
			 */
			handleFileDragOver(event) {
				event.preventDefault();
				event.dataTransfer.dropEffect = 'copy';
			},
	
			/**
			 * Clear file input
			 */
			clearFileInput() {
				const fileInput = document.querySelector('input[type="file"]');
				if (fileInput) {
					fileInput.value = '';
				}
				vueData.ui_state.import_file_content = '';
			},
	
			/**
			 * Import template from selected source
			 */
			async importFromSelectedSource() {
				const tabIndex = vueData.ui_state.import_tab || 0;
	
				try {
					switch (tabIndex) {
						case 0: // Database templates
							const templateId = vueData.ui_state.selected_template_id;
							const deviceType = vueData.ui_state.selected_device_type || 'Desktop';
	
							if (!templateId) {
								this.showNotification('Vui lòng chọn template từ danh sách', 'warning');
								return;
							}
	
							await this.loadTemplateFromDB(templateId, deviceType);
							break;
	
						case 1: // File upload
							const fileInput = document.querySelector('input[type="file"]');
							const file = fileInput?.files[0];
	
							if (!file) {
								this.showNotification('Vui lòng chọn file JSON để import', 'warning');
								return;
							}
	
							await this.loadTemplateFromFile(file);
							break;
	
						case 2: // URL import
							const url = vueData.ui_state.import_url?.trim();
	
							if (!url) {
								this.showNotification('Vui lòng nhập URL của template', 'warning');
								return;
							}
	
							await this.loadTemplateFromURL(url);
							break;
	
						default:
							this.showNotification('Tab import không hợp lệ', 'warning');
					}
				} catch (error) {
					console.error('Import error:', error);
					this.showNotification('Lỗi khi import template', 'error');
				}
			},
	
			/**
			 * Cancel import dialog
			 */
			cancelImport() {
				vueData.ui_state.show_import_dialog = false;
				vueData.ui_state.import_tab = 0;
				vueData.ui_state.selected_template_id = null;
				vueData.ui_state.selected_device_type = 'Desktop';
				vueData.ui_state.import_file_content = '';
				vueData.ui_state.import_url = '';
				this.clearFileInput();
			},
	
			/**
			 * Select template from list
			 */
			selectTemplate(templateId) {
				vueData.ui_state.selected_template_id = templateId;
			},
	
			/**
			 * Change device type for import
			 */
			changeImportDeviceType(deviceType) {
				vueData.ui_state.selected_device_type = deviceType;
			},
	
			/**
			 * Preview template before import
			 */
			async previewTemplate(templateId, deviceType) {
				try {
					// This could show a preview modal or quick info
					this.showNotification(`Preview cho Template ID: ${templateId} (${deviceType})`, 'info');
	
					// Optionally load template info without applying
					// const response = await this.getTemplateInfo(templateId);
	
				} catch (error) {
					console.error('Preview error:', error);
					this.showNotification('Lỗi khi preview template', 'error');
				}
			},
	
			/**
			 * Get template information without loading
			 */
			async getTemplateInfo(templateId) {
				try {
					const payload = { MenuBookID: templateId };
	
					return new Promise((resolve, reject) => {
						ajaxCALL("/eorder/MenuBook_Select_ById", payload,
							(response) => {
								resolve(response);
							},
							(error) => {
								reject(error);
							}
						);
					});
				} catch (error) {
					console.error('Get template info error:', error);
					throw error;
				}
			},
	
			// ========================
			// TEMPLATE LOADING METHODS
			// ========================
	
			/**
			 * Load template from database by ID
			 */
			async loadTemplateFromDB(templateId, deviceType = 'Desktop') {
				if (!templateId) {
					this.showNotification('Không có template ID để tải', 'warning');
					return;
				}
	
				try {
					// Show loading
					vueData.v_menubook_loading = true;
					vueData.loading_message = `Đang tải template ${deviceType}...`;
	
					// Call API to get template
					const payload = { MenuBookID: templateId };
	
					await new Promise((resolve, reject) => {
						ajaxCALL("/eorder/MenuBook_Select_ById", payload,
							(response) => {
								this.processLoadedTemplate(response, deviceType);
								resolve(response);
							},
							(error) => {
								console.error('Error loading template:', error);
								this.showNotification('Lỗi khi tải template: ' + (error.message || 'Unknown error'), 'error');
								reject(error);
							}
						);
					});
	
				} catch (error) {
					console.error('Load template error:', error);
					this.showNotification('Lỗi khi tải template', 'error');
				} finally {
					// Hide loading
					vueData.v_menubook_loading = false;
					vueData.loading_message = '';
				}
			},
	
			/**
			 * Process loaded template from API response
			 */
			processLoadedTemplate(response, deviceType) {
				try {
					let templateData = null;
					let menuBookInfo = null;
	
					// Extract data from API response
					if (response.data && Array.isArray(response.data) && response.data.length > 0) {
						if (response.data[0] && response.data[0].length > 0) {
							menuBookInfo = response.data[0][0];
						}
					} else if (Array.isArray(response) && response.length > 0) {
						if (Array.isArray(response[0]) && response[0].length > 0) {
							menuBookInfo = response[0][0];
						} else if (response[0] && typeof response[0] === 'object') {
							menuBookInfo = response[0];
						}
					}
	
					if (!menuBookInfo) {
						throw new Error('Không tìm thấy thông tin template');
					}
	
					// Get template by device type
					let templateString = '';
					switch (deviceType) {
						case 'Desktop':
							templateString = menuBookInfo.TemplateDesktop || '';
							break;
						case 'Tablet':
							templateString = menuBookInfo.TemplateIpad || '';
							break;
						case 'Mobile':
							templateString = menuBookInfo.TemplateMobile || '';
							break;
						default:
							templateString = menuBookInfo.TemplateDesktop || '';
					}
	
					if (!templateString || templateString.trim() === '') {
						throw new Error(`Template ${deviceType} không có dữ liệu`);
					}
	
					// Parse and load template
					templateData = JSON.parse(templateString);
					this.reconstructCanvas(templateData);
	
					// Update current menubook info
					vueData.current_menubook_info = {
						TagBook: menuBookInfo.TagBook,
						MenuBookID: menuBookInfo.MenuBookID,
						TenBook: menuBookInfo.TenBook || '',
						PhanHieu_ID: menuBookInfo.PhanHieu_ID || null,
						Thumbnail_FileID: menuBookInfo.Thumbnail_FileID || '',
						Is_TamKhoa: menuBookInfo.Is_TamKhoa ?? 0,
						CuaHangApDungID: menuBookInfo.ApDung_CuaHangID || null
					};
	
					this.showNotification(`Đã tải template ${deviceType} thành công`, 'success');
	
					// Close import dialog if open
					if (vueData.ui_state) {
						vueData.ui_state.show_import_dialog = false;
					}
	
				} catch (error) {
					console.error('Error processing template:', error);
					this.showNotification('Lỗi khi xử lý template: ' + error.message, 'error');
				}
			},
	
			/**
			 * Load template from file (JSON import)
			 */
			async loadTemplateFromFile(file) {
				if (!file) {
					this.showNotification('Không có file để tải', 'warning');
					return;
				}
	
				try {
					const text = await this.readFileAsText(file);
					const templateData = JSON.parse(text);
	
					this.reconstructCanvas(templateData);
					this.showNotification('Đã tải template từ file thành công', 'success');
	
					// Close import dialog
					if (vueData.ui_state) {
						vueData.ui_state.show_import_dialog = false;
					}
	
				} catch (error) {
					console.error('Error loading file:', error);
					this.showNotification('Lỗi khi đọc file: ' + error.message, 'error');
				}
			},
	
			/**
			 * Read file as text
			 */
			readFileAsText(file) {
				return new Promise((resolve, reject) => {
					const reader = new FileReader();
					reader.onload = (e) => resolve(e.target.result);
					reader.onerror = (e) => reject(new Error('Lỗi khi đọc file'));
					reader.readAsText(file);
				});
			},
	
			/**
			 * Import template handler
			 */
			async importTemplate(source, data = null) {
				try {
					switch (source) {
						case 'database':
							if (data && data.templateId && data.deviceType) {
								await this.loadTemplateFromDB(data.templateId, data.deviceType);
							} else {
								this.showNotification('Thiếu thông tin template để tải', 'warning');
							}
							break;
	
						case 'file':
							if (data && data.file) {
								await this.loadTemplateFromFile(data.file);
							} else {
								this.showNotification('Không có file được chọn', 'warning');
							}
							break;
	
						case 'url':
							if (data && data.url) {
								await this.loadTemplateFromURL(data.url);
							} else {
								this.showNotification('Không có URL được cung cấp', 'warning');
							}
							break;
	
						default:
							this.showNotification('Phương thức import không được hỗ trợ', 'warning');
					}
				} catch (error) {
					console.error('Import template error:', error);
					this.showNotification('Lỗi khi import template', 'error');
				}
			},
	
			/**
			 * Load template from URL
			 */
			async loadTemplateFromURL(url) {
				try {
					const response = await fetch(url);
					if (!response.ok) {
						throw new Error(`HTTP ${response.status}: ${response.statusText}`);
					}
	
					const templateData = await response.json();
					this.reconstructCanvas(templateData);
					this.showNotification('Đã tải template từ URL thành công', 'success');
	
					// Close import dialog
					if (vueData.ui_state) {
						vueData.ui_state.show_import_dialog = false;
					}
	
				} catch (error) {
					console.error('Error loading from URL:', error);
					this.showNotification('Lỗi khi tải từ URL: ' + error.message, 'error');
				}
			},
	
			// ========================
			// URL & INITIALIZATION
			// ========================
	
			// extractMenuBookIdFromUrl() {
			// 	this.menuBookId = 14;
			// 	vueData.url_menubook_id = 14;
			// 	console.log('Set MenuBook ID cứng:', this.menuBookId);
			// 	return true;
			// },
	
			processMenuBookData() {
				if (!this.menubookData) {
					console.error('No MenuBook data received');
					return;
				}
	
				let menuBookInfo = null;
				if (this.menubookData.data && Array.isArray(this.menubookData.data) && this.menubookData.data.length > 0) {
					if (this.menubookData.data[0] && this.menubookData.data[0].length > 0) {
						menuBookInfo = this.menubookData.data[0][0];
					}
				} else if (Array.isArray(this.menubookData) && this.menubookData.length > 0) {
					if (Array.isArray(this.menubookData[0]) && this.menubookData[0].length > 0) {
						menuBookInfo = this.menubookData[0][0];
					} else if (this.menubookData[0] && typeof this.menubookData[0] === 'object') {
						menuBookInfo = this.menubookData[0];
					}
				}
	
				if (!menuBookInfo) {
					console.error('MenuBook info not found in any format');
					this.createNewPage();
					return;
				}
	
				if (!menuBookInfo.MenuBookID) {
					console.error('MenuBookID missing from:', menuBookInfo);
					this.createNewPage();
					return;
				}
	
				const newMenubookInfo = {
					TagBook: menuBookInfo.TagBook,
					MenuBookID: menuBookInfo.MenuBookID,
					TenBook: menuBookInfo.TenBook || '',
					PhanHieu_ID: menuBookInfo.PhanHieu_ID || null,
					Thumbnail_FileID: menuBookInfo.Thumbnail_FileID || '',
					Is_TamKhoa: menuBookInfo.Is_TamKhoa ?? 0,
					CuaHangApDungID: menuBookInfo.ApDung_CuaHangID || null
				};
				vueData.current_menubook_info = newMenubookInfo;
				const isFirstLoad = !vueData.ui_state.auto_loaded;
				vueData.ui_state.auto_loaded = true;
				this.autoLoadBestAvailableTemplate(menuBookInfo, isFirstLoad);
			},
	
			autoLoadBestAvailableTemplate(menuBookInfo) {
				if (!menuBookInfo) {
					this.createNewPage();
					return;
				}
	
				const parseTemplate_Desktop = menuBookInfo.TemplateDesktop ? JSON.parse(menuBookInfo.TemplateDesktop) : null;
				const parseTemplate_Tablet = menuBookInfo.TemplateIpad ? JSON.parse(menuBookInfo.TemplateIpad) : null;
				const parseTemplate_Mobile = menuBookInfo.TemplateMobile ? JSON.parse(menuBookInfo.TemplateMobile) : null;
				const hasPageNumber = (page) => {
					return (page.elements || []).some(el =>
						el.type === 'group' &&
						el.children?.some(child => child.isAutoPageNumber === true)
					);
				};
	
	
				const applyPageNumbers = (template) => {
					template?.forEach((page, index) => {
						if (index !== 0 && index !== template.length - 1) {
							page.elements = page.elements || [];
	
							// Tìm group chứa page-number do hệ thống sinh ra
							const existingGroup = page.elements.find(el =>
								el.type === 'group' &&
								el.isAutoPageNumber === true &&
								el.children?.some(child => child.role === 'page-number')
							);
	
							const createPageNumberGroup = (index) => {
								const groupId = Date.now() + Math.random();
								return {
									id: groupId,
									type: "group",
									name: "Page number",
									isAutoPageNumber: true,
									x: 443,
									y: 22,
									width: 50,
									height: 50,
									children: [
										{
											id: Date.now() + Math.random(),
											groupId: groupId,
											type: "text-element",
											role: "page-number",
											relative_x: 20,
											relative_y: 10,
											content: (index).toString(),
											style: {
												fontSize: "14px",
												color: "#333",
												fontFamily: "Inter",
												textAlign: "center",
												backgroundColor: "transparent"
											}
										}
									]
								};
							};
	
							if (existingGroup) {
								// Cập nhật nội dung nếu không đúng số
								const numberElement = existingGroup.children.find(c => c.role === 'page-number');
								if (numberElement && numberElement.content !== `${index + 1}`) {
									numberElement.content = `${index + 1}`;
								}
							} else {
								// Chưa có thì thêm mới
								page.elements.unshift(createPageNumberGroup(index));
							}
						}
	
					});
				};
	
				applyPageNumbers(parseTemplate_Desktop);
				applyPageNumbers(parseTemplate_Tablet);
				applyPageNumbers(parseTemplate_Mobile);
	
				let templateToLoad = parseTemplate_Desktop || parseTemplate_Tablet || parseTemplate_Mobile;
				if (templateToLoad) {
					this.reconstructCanvas(templateToLoad);
					this.$nextTick(() => {
						this.showNotification(`Đã tải template thành công`, 'success');
					});
				} else {
					this.createNewPage();
					this.showNotification('MenuBook chưa có template, đã tạo trang mới', 'info');
				}
			},
	
			handleCorruptedTemplate(templateData, deviceType) {
				console.error('=== CORRUPTED TEMPLATE DETECTED ===');
				console.error(`${deviceType} template is corrupted or incomplete`);
	
				let fixedTemplate = this.attemptTemplateRepair(templateData);
	
				if (fixedTemplate) {
					try {
						const parsedTemplate = JSON.parse(fixedTemplate);
						this.reconstructCanvas(parsedTemplate);
						this.showNotification(`Đã sửa và tải template ${deviceType} thành công`, 'success');
						return;
					} catch (error) {
						console.error('Repair attempt failed:', error);
					}
				}
				try {
					const sampleTemplate = this.createSampleTemplate();
					this.reconstructCanvas(sampleTemplate);
					this.showNotification(`Template ${deviceType} bị lỗi, đã tạo template mẫu`, 'warning');
					return;
				} catch (sampleError) {
					console.error('Sample template also failed:', sampleError);
				}
	
				this.createNewPage();
				this.showNotification(`Template ${deviceType} bị lỗi, đã tạo trang mới`, 'error');
			},
	
			attemptTemplateRepair(templateData) {
				let repaired = templateData.trim();
				repaired = repaired.replace(/,\s*([}\]])/g, '$1');
	
				if (repaired.startsWith('[') && !repaired.endsWith(']')) {
					repaired += ']';
				} else if (repaired.startsWith('{') && !repaired.endsWith('}')) {
					repaired += '}';
				}
	
				const lastValidChar = Math.max(repaired.lastIndexOf(']'), repaired.lastIndexOf('}'));
				if (lastValidChar > 0 && lastValidChar < repaired.length - 1) {
					repaired = repaired.substring(0, lastValidChar + 1);
				}
	
				try {
					JSON.parse(repaired);
					return repaired;
				} catch (error) {
					return null;
				}
			},
	
			createNewPage() {
				this.pages = [{
					id: Date.now(),
					type: 'Desktop',
					name: 'Trang bìa',
					background: null,
					elements: []
				}];
				this.currentPageIndex = 0;
				this.updateJson();
			},
	
			createSampleTemplate() {
				const baseTime = Date.now();
				return [{
					pageNumber: 1,
					TypePage: "Desktop",
					layer: [{ background: null }],
					elements: [{
						id: baseTime,
						type: "group",
						name: "Sample Item",
						stt: itemData.MaSoSanPham || '',
						x: 50,
						y: 50,
						width: 250,
						height: 100,
						children: [{
							id: baseTime + 1,
							groupId: baseTime,
							type: "image-element",
							relative_x: 0,
							relative_y: 0,
							width: 80,
							height: 80,
							src: "/_cdn/zen-eorder/menu-online/menu_2.jpt",
							style: { borderRadius: "8px" }
						}, {
							id: baseTime + 2,
							groupId: baseTime,
							type: "text-element",
							relative_x: 90,
							relative_y: 10,
							content: "1. Sample Menu Item",
							style: { fontSize: "18px", fontWeight: "bold", color: "#333333", fontFamily: "Inter", backgroundColor: "transparent" }
						}, {
							id: baseTime + 3,
							groupId: baseTime,
							type: "text-element",
							relative_x: 170,
							relative_y: 45,
							content: "99,000đ",
							style: { fontSize: "16px", color: "#e74c3c", fontFamily: "Inter", backgroundColor: "transparent" }
						}]
					}]
				}];
			},
	
			reconstructCanvas(templateData) {
				try {
					this.pages = [];
					this.currentPageIndex = 0;
					this.selectedElement = null;
					let pagesData = [];
	
					if (templateData.pages) {
						pagesData = templateData.pages;
					} else if (Array.isArray(templateData)) {
						pagesData = templateData;
					} else {
						throw new Error('Format JSON không được hỗ trợ');
					}
	
					pagesData.forEach((pageData, index) => {
						const newPage = {
							id: Date.now() + index,
							type: pageData.TypePage || pageData.type || 'Desktop',
							name: pageData.pageName || pageData.name || this.getDefaultPageName({ type: pageData.TypePage || 'Desktop' }, index),
							background: this.extractBackground(pageData),
							elements: this.reconstructElements(pageData.elements || [])
						};
						this.pages.push(newPage);
					});
					if (this.pages.length > 0) {
						this.currentPageIndex = 0;
					}
	
					this.updateAutoItemIndex();
	
					this.updateJson();
				} catch (error) {
					console.error('Error reconstructing canvas:', error);
					throw error;
				}
			},
	
			extractBackground(pageData) {
				if (pageData.layer && pageData.layer[0] && pageData.layer[0].background) {
					return pageData.layer[0].background;
				}
				return pageData.background || null;
			},
	
			reconstructElements(elements) {
				if (!Array.isArray(elements)) return [];
				return elements.map(el => {
					const newElement = { ...el, id: Date.now() + Math.random() };
					if (newElement.type === 'group' && newElement.children) {
						const newGroupId = newElement.id;
						newElement.children = newElement.children.map(child => ({
							...child,
							id: Date.now() + Math.random(),
							groupId: newGroupId
						}));
					}
					return newElement;
				});
			},
	
			// ========================
			// DRAG & DROP
			// ========================
	
			onDragStart(event, data, type) {
				this.draggedData = {
					data: JSON.parse(JSON.stringify(data)),
					type
				};
	
				// ✅ Lưu snapshot trước khi kéo (để Undo quay lại đúng vị trí cũ)
				this.beforeDragSnapshot = JSON.stringify(this.currentPage);
			},
	
			onDrop(event) {
				event.preventDefault();
				if (!this.draggedData) return;
	
				const rect = this.$refs.canvas.getBoundingClientRect();
				const x = event.clientX - rect.left;
				const y = event.clientY - rect.top;
				let newElement = null;
	
				// ✅ Nếu kéo hình và đang chọn 1 image-element thì thay ảnh
				if (
					this.draggedData.type === 'image' &&
					this.selectedElement &&
					this.selectedElement.type === 'image-element' &&
					(event.ctrlKey || event.metaKey)
				) {
					this.selectedElement.src = this.draggedData.data;
					this.updateJson();
					this.draggedData = null;
					return;
				}
	
				// ✅ Nếu kéo menu item
				if (this.draggedData.type === 'menu-item') {
					const itemData = this.draggedData.data;
	
					// Đánh dấu item đã dùng
					const item = this.displayItems.find(it => it.id === itemData.id);
					if (item) item.used = true;
	
					const groupID = Date.now();
	
					const children = [
						// Ảnh món ăn
						{
							id: groupID + 1,
							groupId: groupID,
							type: 'image-element',
							relative_x: 0,
							relative_y: 0,
							width: 180,
							height: 180,
							src: itemData.image,
							rotation: 0,
							style: { borderRadius: '8px' },
							originalAspectRatio: null
						},
						// STT
						{
							id: groupID + 0.5,
							groupId: groupID,
							type: 'text-element',
							zIndex: 1,
							role: 'stt',
							content: `${itemData.MaSoSanPham || ''}.`,
							relative_x: 75,
							relative_y: 20,
							style: { fontSize: '14px', fontWeight: 'bold', color: '#000', fontFamily: 'Inter' }
	
						},
						// Tên món
						{
							id: groupID + 2.1,
							groupId: groupID,
							type: 'text-element',
							zIndex: 1,
							relative_x: 100,
							relative_y: 25,
							content: itemData.name,
							style: { fontSize: '16px', fontWeight: 'bold', color: '#333', fontFamily: 'Inter' }
						},
						// Tên ngắn
						{
							id: groupID + 2.5,
							groupId: groupID,
							type: 'text-element',
							zIndex: 1,
							relative_x: 110,
							relative_y: 50,
							content: itemData.TenNgan || '',
							style: { fontSize: '14px', color: '#333', fontFamily: 'Inter' }
						},
						// Giá
						{
							id: groupID + 3,
							groupId: groupID,
							type: 'text-element',
							zIndex: 1,
							role: 'price',
							relative_x: 170,
							relative_y: 70,
							content: itemData.price,
							style: { fontSize: '16px', color: '#e74c3c', fontFamily: 'Inter' }
						}
					];
	
					if (itemData.Is_BestSeller) {
						children.push({
							id: groupID + 4,
							groupId: groupID,
							type: 'image-element',
							relative_x: 200,
							relative_y: -30,
							width: 55,
							height: 50,
							src: '/_cdn/zen-eorder/trang-thai-icon/ic-best-seller.png',
							style: {},
							originalAspectRatio: null
						});
					}
	
					if (itemData.Is_Signature) {
						children.push({
							id: groupID + 5,
							groupId: groupID,
							type: 'image-element',
							relative_x: 193,
							relative_y: -30,
							width: 65,
							height: 60,
							src: '/_cdn/zen-eorder/trang-thai-icon/ic-signature.png',
							style: { transform: 'scaleX(-1)' },
							originalAspectRatio: null
						});
					}
	
					if (itemData.Is_HetMon) {
						children.push({
							id: groupID + 6,
							groupId: groupID,
							type: 'image-element',
							relative_x: 200,
							relative_y: -30,
							width: 55,
							height: 50,
							src: '/_cdn/zen-eorder/trang-thai-icon/ic-het-mon.png',
							style: {},
							originalAspectRatio: null
						});
					}
	
					newElement = {
						id: groupID,
						type: 'group',
						id_SanPham: itemData.id_SanPham || '',
						name: itemData.name,
						stt: itemData.MaSoSanPham || '',
						MaSoSanPham: itemData.MaSoSanPham || '',
						Is_BestSeller: itemData.Is_BestSeller || false,
						Is_Signature: itemData.Is_Signature || false,
						Is_HetMon: itemData.Is_HetMon || false,
						x,
						y,
						width: 250,
						height: 100,
						children
					};
				}
	
				// ✅ Nếu kéo hình ảnh — và KHÔNG có selectedElement → tạo hình mới với tỉ lệ gốc
				else if (this.draggedData.type === 'image') {
					const droppedSrc = this.draggedData.data; // ✅ lưu lại src trước
					this.draggedData = null; // tránh mất dữ liệu khi onload
	
					const img = new Image();
					img.onload = () => {
						const ratio = img.width / img.height;
						const defaultWidth = 120;
						const defaultHeight = Math.round(defaultWidth / ratio);
	
						const newElement = {
							id: Date.now(),
							type: 'image-element',
							x,
							y,
							width: defaultWidth,
							height: defaultHeight,
							rotation: 0,
							src: droppedSrc, // ✅ dùng biến cục bộ
							style: { borderRadius: '8px' },
							originalAspectRatio: ratio
						};
	
						if (this.currentPage) {
							this.currentPage.elements.push(newElement);
							this.updateJson();
							this.autoItemIndex++;
						}
					};
					img.src = droppedSrc; // ✅ dùng biến cục bộ
				}
	
				// ✅ Thêm vào trang hiện tại cho các case đã có newElement sẵn
				if (newElement && this.currentPage && this.draggedData.type !== 'image') {
					this.currentPage.elements.push(newElement);
					this.updateJson();
					this.autoItemIndex++;
				}
	
				this.draggedData = null;
			},
	
			// ========================
			// ELEMENT MANIPULATION
			// ========================
	
			startDrag(el, e, type) {
				e.preventDefault();
				e.stopPropagation();
				this.dragType = type;
				this.draggingElement = el;
				this.selectAny(el, e);
	
				const canvasRect = this.$refs.canvas.getBoundingClientRect();
				const invZoom = 1 / this.zoomLevel;
	
				// Tính vị trí chuột trong hệ toạ độ của canvas
				const mouseX = (e.clientX - canvasRect.left) * invZoom;
				const mouseY = (e.clientY - canvasRect.top) * invZoom;
	
				if (type === 'child') {
					const group = this.currentPage.elements.find(group => group.id === el.groupId);
					this.dragOffset = {
						x: mouseX - (group.x + el.relative_x),
						y: mouseY - (group.y + el.relative_y)
					};
				} else {
					this.dragOffset = {
						x: mouseX - el.x,
						y: mouseY - el.y
					};
				}
	
				window.addEventListener('mousemove', this.onDragging);
				window.addEventListener('mouseup', this.stopDrag);
			},
	
			onDragging(e) {
				e.preventDefault();
				if (!this.draggingElement) return;
	
				const canvasRect = this.$refs.canvas.getBoundingClientRect();
				const invZoom = 1 / this.zoomLevel;
				const mouseX = (e.clientX - canvasRect.left) * invZoom;
				const mouseY = (e.clientY - canvasRect.top) * invZoom;
	
				if (this.dragType === 'child') {
					const group = this.currentPage.elements.find(g => g.id === this.draggingElement.groupId);
					if (group) {
						this.draggingElement.relative_x = mouseX - this.dragOffset.x - group.x;
						this.draggingElement.relative_y = mouseY - this.dragOffset.y - group.y;
					}
				} else {
					this.draggingElement.x = mouseX - this.dragOffset.x;
					this.draggingElement.y = mouseY - this.dragOffset.y;
				}
	
				// this.updateJson();
			},
	
			stopDrag() {
				if (this.selectedElement?.role && ['best-seller', 'signature', 'het-mon'].includes(this.selectedElement.role)) {
					this.selectedElement.customPositioned = true;
				}
	
				if (this.draggingElement) {
					// ✅ Cập nhật JSON 1 lần khi thả chuột
					this.updateJson();
	
					// ✅ Chỉ thêm vào lịch sử nếu có thay đổi thật
					const afterDragSnapshot = JSON.stringify(this.currentPage);
					if (this.beforeDragSnapshot !== afterDragSnapshot) {
						this.saveHistory?.(); // gọi hàm lưu undo stack nếu có
					}
				}
	
				window.removeEventListener('mousemove', this.onDragging);
				window.removeEventListener('mouseup', this.stopDrag);
				this.draggingElement = null;
				this.dragType = null;
			},
	
			selectElement(el) {
				// đơn chọn (không phím tắt)
				this.selectedIds = [String(el.id)];
				this.selectedElement = el;
				if (el && el.type === 'image-element' && !el.originalAspectRatio) {
					el.originalAspectRatio = el.width / el.height;
				}
			},
	
			deselectAll() {
				this.clearSelection();
			},
	
			deleteElement(el) {
	
				if (!this.currentPage) return;
				const index = this.currentPage.elements.findIndex(e => e.id === el.id);
				if (index !== -1) {
					this.currentPage.elements.splice(index, 1);
	
					// Nếu là group và có id_SanPham → enable lại món
					if (el.type === 'group' && el.id_SanPham) {
						const item = this.displayItems.find(item => item.id_SanPham === el.id_SanPham);
						if (item) item.used = false;
					}
	
					this.updateJson();
					this.selectedElement = null;
				}
			},
	
			// removeImage(child) {
			// 	if (!child || !child.groupId) return;
	
			// 	// Tìm group chứa phần tử này
			// 	const group = this.currentPage.elements.find(el => el.type === 'group' && el.id === child.groupId);
			// 	if (!group) return;
	
			// 	// Xóa phần tử khỏi group.children
			// 	group.children = group.children.filter(c => c.id !== child.id);
	
			// 	// Nếu đang chọn phần tử đó thì clear selected
			// 	if (this.selectedElement && this.selectedElement.id === child.id) {
			// 		this.selectedElement = null;
			// 	}
	
			// 	this.updateJson();
			// },
	
			// ========================
			// COPY & PASTE
			// ========================
	
			copyElement() {
				if (!this.selectedElement) return;
				this.copiedElement = JSON.parse(JSON.stringify(this.selectedElement));
			},
	
			pasteElement() {
				if (!this.copiedElement || !this.currentPage) return;
	
				const newElement = JSON.parse(JSON.stringify(this.copiedElement));
				newElement.id = Date.now();
	
				if (newElement.groupId) {
					this.showNotification("Không thể dán phần tử con (child) riêng lẻ.", 'warning');
					return;
				}
	
				if (newElement.type === 'group') {
					const newGroupId = Date.now();
					newElement.id = newGroupId;
					newElement.x += 20;
					newElement.y += 20;
					newElement.children.forEach(child => {
						child.id = Date.now() + Math.random();
						child.groupId = newGroupId;
					});
				} else {
					newElement.x += 20;
					newElement.y += 20;
				}
	
				this.currentPage.elements.push(newElement);
				this.selectElement(newElement);
				this.updateJson();
			},
	
			// ========================
			// UTILITIES
			// ========================
	
			updateAutoItemIndex() {
				let maxSTT = 0;
				this.pages.forEach(page => {
					page.elements.forEach(el => {
						if (el.type === 'group' && el.stt) {
							maxSTT = Math.max(maxSTT, el.stt);
						}
					});
				});
				this.autoItemIndex = maxSTT + 1;
			},
	
			// reindexSTT() {
			// 	let totalIndex = 1;
			// 	this.pages.forEach(page => {
			// 		const groups = page.elements.filter(el => el.type === 'group');
			// 		groups.forEach((group) => {
			// 			group.STT = totalIndex;
	
			// 			// 🔍 Tìm child có role là 'stt'
			// 			const sttElement = group.children.find(child => child.type === 'text-element' && child.role === 'stt');
			// 			if (sttElement) {
			// 				sttElement.content = `${totalIndex}.`;
			// 			}
	
			// 			totalIndex++;
			// 		});
			// 	});
			// 	this.autoItemIndex = totalIndex;
			// },
	
			updateJson() {
				// Cập nhật icon động cho các group dựa vào Is_BestSeller và Is_Signature
				this.pages.forEach(p => {
					p.elements.forEach(el => {
						if (el.type === 'group') this.ensureDynamicIcons(el);
					});
				});
				this.exportedJson = JSON.stringify({
					pages: this.pages.map((p, index) => ({
						pageNumber: index + 1,
						TypePage: p.type,
						pageName: p.name || this.getDefaultPageName(p, index),
						layer: [{ background: p.background }],
						elements: p.elements
					}))
				}, null, 2);
	
				// History management
				const snapshot = JSON.parse(JSON.stringify(this.pages));
				this.history = this.history.slice(0, this.historyIndex + 1);
				this.history.push(snapshot);
				this.historyIndex++;
			},
	
			updateJsonWithoutHistory() {
				this.exportedJson = JSON.stringify({
					pages: this.pages.map((p, index) => ({
						pageNumber: index + 1,
						TypePage: p.type,
						layer: [{ background: p.background }],
						elements: p.elements
					}))
				}, null, 2);
			},
	
			exportJson() {
				const jsonStr = this.exportedJson;
				const blob = new Blob([jsonStr], { type: 'application/json' });
				const url = URL.createObjectURL(blob);
				const link = document.createElement('a');
				link.href = url;
				link.download = `menu-template-${Date.now()}.json`;
				document.body.appendChild(link);
				link.click();
				document.body.removeChild(link);
				URL.revokeObjectURL(url);
			},
	
			// ========================
			// UNDO & REDO
			// ========================
	
			undo() {
				if (this.historyIndex > 0) {
					this.historyIndex--;
					this.pages = JSON.parse(JSON.stringify(this.history[this.historyIndex]));
	
					this.updateJsonWithoutHistory();
				}
			},
	
			redo() {
				if (this.historyIndex < this.history.length - 1) {
					this.historyIndex++;
					this.pages = JSON.parse(JSON.stringify(this.history[this.historyIndex]));
	
					this.updateJsonWithoutHistory();
				}
			},
	
			// ========================
			// SAVE & NAVIGATION
			// ========================
	
			/**
			 * Save menu (simplified)
			 */
			async saveMenu() {
				if (!vueData.current_menubook_info || !vueData.current_menubook_info.MenuBookID) {
					this.showNotification('Không xác định được MenuBook để lưu', 'error');
					return;
				}
	
				try {
					const pagesByType = {
						Desktop: this.pages.filter(p => p.type === 'Desktop'),
						Tablet: this.pages.filter(p => p.type === 'Tablet'),
						Mobile: this.pages.filter(p => p.type === 'Mobile')
					};
	
					const payload = {
						MenuBookID: vueData.current_menubook_info.MenuBookID,
						TemplateDesktop: pagesByType.Desktop.length > 0 ? JSON.stringify(pagesByType.Desktop) : '',
						TemplateIpad: pagesByType.Tablet.length > 0 ? JSON.stringify(pagesByType.Tablet) : '',
						TemplateMobile: pagesByType.Mobile.length > 0 ? JSON.stringify(pagesByType.Mobile) : ''
					};
	
	
					await new Promise((resolve, reject) => {
						ajaxCALL("/eorder/MenuBook_UpdateTemplate", payload,
							(res) => {
								vueData.ui_state.show_save_success = true;
								this.isSaved = true;
								this.showNotification('Lưu menu thành công!', 'success');
								resolve(res);
							},
							(err) => {
								console.error('Lỗi khi lưu:', err);
								this.showNotification('Lỗi khi lưu menu: ' + (err.message || 'Unknown error'), 'error');
								reject(err);
							}
						);
					});
	
				} catch (error) {
					console.error('Save error:', error);
					this.showNotification('Lỗi khi lưu menu', 'error');
				}
			},
	
			/**
			 * Go back to menu list
			 */
			goBackToMenuList() {
				if (!this.isSaved) {
					const hasChanges = this.pages.some(page => page.elements.length > 0);
					if (hasChanges) {
						confirm({
							title: 'Bạn có thay đổi chưa lưu. Bạn có chắc muốn rời khỏi trang này?',
							action: () => {
								window.location.href = '/menu-admin';
							}
						});
						return; // dừng lại nếu chưa confirm
					}
				}
	
				// Đã lưu rồi hoặc không có gì thay đổi → đi luôn
				window.location.href = '/menu-admin';
			},
	
			/**
			 * Open import dialog (simplified)
			 */
			openImportDialog() {
				vueData.ui_state.show_import_dialog = true;
				window.open('/menu-online?MenuBookID=' + vueData.MenuBookID + '&CuaHangID=' + vueData.CuaHangID_Local)
			},
			/**
			 * Show notification (simple toast)
			 */
			showNotification(message, type = 'info') {
				// Simple toast notification
				const toast = document.createElement('div');
				toast.className = `toast toast-${type}`;
				toast.innerHTML = `
																																																								<div class="toast-content">
																																																									<i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : type === 'warning' ? 'exclamation-triangle' : 'info-circle'}"></i>
																																																									<span>${message}</span>
																																																								</div>
																																																							`;
				document.body.appendChild(toast);
				// Auto remove after 3 seconds
				setTimeout(() => {
					if (toast.parentNode) {
						toast.parentNode.removeChild(toast);
					}
				}, 3000);
			},
			// ========================
			// ✅ ENHANCED KEYBOARD SHORTCUTS
			// ========================
	
			/**
			 * Handle keyboard shortcuts
			 */
			handleKeydown(e) {
	
				const isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;
				const ctrlKey = isMac ? e.metaKey : e.ctrlKey;
	
				// ESC: Cancel edit or deselect
				if (e.key === 'Escape') {
					e.preventDefault();
					if (this.editingPageIndex !== -1) {
						this.cancelEditPageName(this.editingPageIndex);
					} else if (this.selectedElement) {
						this.selectedElement = null;
					}
				}
	
				// F2: Rename current page
				else if (e.key === 'F2') {
					e.preventDefault();
					if (this.currentPageIndex >= 0) {
						this.startEditPageName(this.currentPageIndex);
					}
				}
	
				// Enter: Finish edit
				else if (e.key === 'Enter' && this.editingPageIndex !== -1) {
	
					e.preventDefault();
					this.finishEditPageName(this.editingPageIndex);
				}
	
				// Ctrl/Cmd + B: Toggle sidebar
				else if (ctrlKey && e.key === 'b') {
					e.preventDefault();
					this.toggleSidebar();
				}
	
				// Ctrl/Cmd + S: Save menu
				else if (ctrlKey && e.key === 's') {
					e.preventDefault();
					this.saveMenu();
				}
	
				// Ctrl/Cmd + N: New page
				else if (ctrlKey && e.key === 'n') {
					e.preventDefault();
					this.addNewPage();
				}
	
				// Ctrl/Cmd + Z: Undo
				else if (ctrlKey && e.key === 'z' && !e.shiftKey) {
					e.preventDefault();
					this.undo();
				}
	
				// Ctrl/Cmd + Shift + Z or Ctrl/Cmd + Y: Redo
				else if (ctrlKey && ((e.key === 'z' && e.shiftKey) || e.key === 'y')) {
					e.preventDefault();
					this.redo();
				}
	
				// Ctrl/Cmd + C: Copy element
				else if (ctrlKey && e.key === 'c') {
					e.preventDefault();
					this.copyElement();
				}
	
				// Ctrl/Cmd + V: Paste element
				else if (ctrlKey && e.key === 'v') {
					e.preventDefault();
					this.pasteElement();
				}
	
				// Ctrl/Cmd + ←: Previous page
				else if (ctrlKey && e.key === 'ArrowLeft') {
					e.preventDefault();
					if (this.currentPageIndex > 0) {
						this.currentPageIndex--;
						this.scrollToActivePage();
					}
				}
	
				// Ctrl/Cmd + →: Next page
				else if (ctrlKey && e.key === 'ArrowRight') {
					e.preventDefault();
					if (this.currentPageIndex < this.pages.length - 1) {
						this.currentPageIndex++;
						this.scrollToActivePage();
					}
				}
	
				// Delete: Delete selected element or current page
				else if (e.key === 'Delete') {
					e.preventDefault();
					if (this.selectedIds.length > 0) {
						this.deleteSelected();
					} else if (this.selectedElement) {
						this.deleteElement(this.selectedElement);
					} else if (e.shiftKey && this.currentPageIndex >= 0) {
						this.confirmDeletePage(this.currentPageIndex);
					}
				}
	
			},
			loadAssets() {
				ajaxCALL("/eorder/HinhAnhQuangCao_Select", {
					LoaiAnh: "MENU_IMG"
				}, (res) => {
					let arrImage = []
					res.data.forEach(item => {
						arrImage.push(item.AnhQuangCao_Url)
					})
					this.imageAssets = res.data
				})
			},
			loadAssets_bg() {
				ajaxCALL("/eorder/HinhAnhQuangCao_Select", {
					LoaiAnh: "MENU_BG"
				}, (res) => {
					let arrImage = []
					res.data.forEach(item => {
						arrImage.push(item.AnhQuangCao_Url)
					})
					this.backgroundAssets = res.data
				})
			},
		},
	
		mounted() {
			this.loadAssets_bg();
			this.loadAssets();
			this.isLoading = this.loading;
			document.addEventListener('keydown', this.handleArrowKey);
			// Load sidebar state and setup event listeners
			this.loadSidebarState();
			window.addEventListener('keydown', this.handleKeydown);
			window.addEventListener('click', this.handleClickOutside);
			document.addEventListener('click', this.handleGlobalClick);
			// Initialize JSON
			this.updateJson();
	
			// Extract MenuBook ID from URL
			// this.extractMenuBookIdFromUrl();
		},
	
		beforeDestroy() {
			window.removeEventListener('keydown', this.handleKeydown);
			window.removeEventListener('click', this.handleClickOutside);
			document.removeEventListener('keydown', this.handleArrowKey);
			document.removeEventListener('click', this.handleGlobalClick);
		}
	}
</script>
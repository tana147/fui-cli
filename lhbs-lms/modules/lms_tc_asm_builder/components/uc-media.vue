<template>
	<v-expansion-panels v-model="mediaPanelOpen">
        <v-expansion-panel>
            <v-expansion-panel-title v-if="!hasMedia" class="pa-2 font-weight-medium">
                <div class="d-flex align-center ga-2 w-100">
                    <span>Media</span>
                    <div v-if="hasMedia" class="d-flex align-center ga-1 flex-wrap">
                        <v-chip v-if="hasYoutube" size="x-small" color="red" variant="tonal">
                            <v-icon start size="13">mdi-video-outline</v-icon>Video
                        </v-chip>
                        <v-chip v-if="hasAudio" size="x-small" color="teal" variant="tonal">
                            <v-icon start size="13">mdi-multimedia</v-icon>Audio
                        </v-chip>
                        <v-chip v-if="hasFiles" size="x-small" color="blue" variant="tonal">
                            <v-icon start size="13">mdi-file</v-icon>{{ fileCount }} file
                        </v-chip>
                    </div>
                </div>
            </v-expansion-panel-title>
            <v-expansion-panel-text>
                <div class="media-type-tabs mt-2" role="tablist">
                    <v-btn class="media-type-tab" :class="{ 'media-type-tab--active': selectedData.media.type === 'YOUTUBE' || selectedData.media.type === 'INTERACTIVE_VIDEO' }"
                        variant="text" @click="selectedData.media.type = selectedData.isInteractiveVideo ? 'INTERACTIVE_VIDEO' : 'YOUTUBE'">
                        <v-icon size="16">mdi-video-outline</v-icon><span>Video</span><i v-if="hasYoutube" class="media-type-dot" />
                    </v-btn>
                    <v-btn class="media-type-tab" :class="{ 'media-type-tab--active': selectedData.media.type === 'RECORD_AUDIO' }"
                        variant="text" @click="selectedData.media.type = 'RECORD_AUDIO'">
                        <v-icon size="16">mdi-music-note-outline</v-icon><span>Audio</span><i v-if="hasAudio" class="media-type-dot" />
                    </v-btn>
                    <v-btn class="media-type-tab" :class="{ 'media-type-tab--active': selectedData.media.type === 'FILE' }"
                        variant="text" @click="selectedData.media.type = 'FILE'">
                        <v-icon size="16">mdi-file-outline</v-icon><span>File</span><i v-if="hasFiles" class="media-type-dot" />
                    </v-btn>
                </div>
                <v-alert class="mt-3" density="compact" variant="tonal" color="info"
                    icon="mdi-information-outline">
                    {{ IsEngLish ? 'Media uploaded to assignments will be added to School Resources.' : 'Media tải lên bài tập sẽ được bổ sung vào Tài nguyên nhà trường.' }}
                </v-alert>

                <div v-if="selectedData.media.type === 'YOUTUBE' || selectedData.media.type === 'INTERACTIVE_VIDEO'" class="d-flex flex-column ga-2 mt-3">
                    <div class="media-input-row pb-2">
                        <v-text-field v-model="selectedData.media.sourceYT.source"
                            :placeholder="IsEngLish ? 'Paste video link' : 'Dán link video...'"
                            :hint="IsEngLish ? '*Paste a YouTube or other video link.' : '*Dán đường link YouTube hoặc video khác'"
                            persistent-hint :clearable="false" @change="emitUpdate" />
                        <v-btn @click="$refs.fileInput.click()" color="primary" variant="outlined">{{ IsEngLish ? 'Upload video' : 'Tải video' }}</v-btn>
                        <input ref="fileInput" type="file" accept="video/*" @change="handleInputChange($event, 'YOUTUBE')" hidden />
                    </div>
                    <div v-if="hasYoutube" class="assignment-media-video-card">
                        <iframe class="assignment-media-video"
                            :src="renderUrlYoutube(selectedData.media.sourceYT.source)" title="YouTube video player"
                            frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                            allowfullscreen />
                        <div class="media-card-footer">
                            <span class="text-caption text-truncate">{{ selectedData.media.sourceYT.name || (IsEngLish ? 'YouTube Video' : 'Video YouTube') }}</span>
                            <v-btn v-if="canSyncResource(selectedData.media.sourceYT)" size="x-small" variant="tonal" color="primary"
                                :loading="isSyncingResource(selectedData.media.sourceYT)" @click="syncExistingResource('VIDEO', selectedData.media.sourceYT)">
                                <v-icon start size="14">mdi-cloud-sync-outline</v-icon>{{ IsEngLish ? 'Sync' : 'Đồng bộ' }}
                            </v-btn>
                            <v-chip v-else-if="isResourceSynced(selectedData.media.sourceYT, 'VIDEO')" size="x-small" color="success" variant="tonal">{{ IsEngLish ? 'Synced' : 'Đã đồng bộ' }}</v-chip>
                            <v-btn class="media-card-delete" size="small" variant="text" color="error"
                                @click="removeYoutube" :aria-label="IsEngLish ? 'Delete video' : 'Xóa video'">
                                <v-icon size="17">mdi-close</v-icon>
                            </v-btn>
                        </div>
                    </div>
                    <div v-else class="assignment-media-empty">
                        <v-icon size="30">mdi-video-off-outline</v-icon>
                        <span>{{ IsEngLish ? 'No video' : 'Chưa có video' }}</span>
                    </div>
                </div>

                <div v-else-if="selectedData.media.type === 'RECORD_AUDIO'" class="d-flex flex-column ga-2 mt-3">
                    <div class="media-input-row mb-2">
                        <v-text-field v-model="selectedData.media.sourceRecord.source"
                            :placeholder="IsEngLish ? 'Paste audio link' : 'Dán link audio...'" :clearable="false" @change="emitUpdate" />
                        <v-btn @click="$refs.inputUploadRecordAudio.click()" variant="outlined" color="primary">{{ IsEngLish ? 'Upload audio' : 'Tải audio' }}</v-btn>
                        <input ref="inputUploadRecordAudio" type="file" accept="audio/*" @change="handleInputChange($event, 'UPLOAD_RECORD_AUDIO')" hidden />
                    </div>
                    <uc-audio-record v-model:file="fileRecordAudio" v-model:src="selectedData.media.sourceRecord.source"
                        v-model:isSaveFile="isSaveFile" @handleSave="handleFileChange(fileRecordAudio, 'RECORD_AUDIO')" />
                    <div v-if="!hasAudio" class="assignment-media-empty">
                        <v-icon size="30">mdi-music-note-off</v-icon>
                        <span>{{ IsEngLish ? 'No audio' : 'Chưa có audio' }}</span>
                    </div>
                    <v-btn v-if="hasAudio" size="small" variant="text" color="error" class="align-self-start" @click="removeAudio">
                        <v-icon start>mdi-delete-outline</v-icon>{{ IsEngLish ? 'Delete audio' : 'Xóa audio' }}
                    </v-btn>
                    <v-btn v-if="hasAudio && canSyncResource(selectedData.media.sourceRecord)" size="small" variant="tonal" color="primary" class="align-self-start"
                        :loading="isSyncingResource(selectedData.media.sourceRecord)" @click="syncExistingResource('AUDIO', selectedData.media.sourceRecord)">
                        <v-icon start>mdi-cloud-sync-outline</v-icon>{{ IsEngLish ? 'Sync audio to Resources' : 'Đồng bộ audio vào Tài nguyên' }}
                    </v-btn>
                    <v-chip v-else-if="hasAudio && isResourceSynced(selectedData.media.sourceRecord, 'AUDIO')" size="small" color="success" variant="tonal" class="align-self-start">{{ IsEngLish ? 'Audio synced' : 'Audio đã đồng bộ' }}</v-chip>
                    <v-btn v-else-if="hasAudio && canSyncLmsFileData(selectedData.media.sourceRecord)" size="small" variant="tonal" color="warning" class="align-self-start"
                        :loading="isSyncingResource(selectedData.media.sourceRecord)" @click="syncMissingLmsFileData('AUDIO', selectedData.media.sourceRecord)">
                        <v-icon start>mdi-file-cloud-outline</v-icon>{{ IsEngLish ? 'Sync LMS FileData' : 'Đồng bộ LMS FileData' }}
                    </v-btn>
                    <v-chip v-else-if="hasAudio && hasResourceNode(selectedData.media.sourceRecord)" size="small" color="warning" variant="tonal" class="align-self-start">{{ IsEngLish ? 'Missing LMS FileData' : 'Thiếu LMS FileData' }}</v-chip>
                </div>

                <div v-else class="d-flex flex-column ga-3 mt-3">
                    <v-btn @click="$refs.inputFile.click()" color="primary" variant="outlined" class="align-self-start">{{ IsEngLish ? 'Upload file' : 'Tải file' }}</v-btn>
                    <input ref="inputFile" type="file" accept=".pdf,.doc,.docx,.ppt,.pptx,image/*" @change="handleInputChange($event, 'FILE')" hidden />

                    <div class="text-subtitle-2">{{ IsEngLish ? 'Images' : 'Hình ảnh' }}</div>
                    <div v-if="images.length" class="assignment-media-image-grid">
                        <div v-for="(file, index) in images" :key="file.id || file.resourceFileId || index" class="assignment-media-image-card">
                            <v-img :src="imageSource(file)" cover class="assignment-media-image-preview">
                                <template #placeholder><div class="d-flex align-center justify-center fill-height"><v-progress-circular indeterminate color="primary" /></div></template>
                            </v-img>
                            <div class="media-card-footer">
                                <span class="text-caption text-truncate">{{ file.name }} <small class="text-medium-emphasis">({{ formatFileSize(file.fileSize) }})</small></span>
                                <v-btn v-if="canSyncResource(file)" size="x-small" variant="tonal" color="primary"
                                    :loading="isSyncingResource(file)" @click="syncExistingResource('IMAGE', file)">
                                    <v-icon start size="14">mdi-cloud-sync-outline</v-icon>{{ IsEngLish ? 'Sync' : 'Đồng bộ' }}
                                </v-btn>
                                <v-chip v-else-if="isResourceSynced(file, 'IMAGE')" size="x-small" color="success" variant="tonal">{{ IsEngLish ? 'Synced' : 'Đã đồng bộ' }}</v-chip>
                                <v-btn v-else-if="canSyncLmsFileData(file)" size="x-small" variant="tonal" color="warning"
                                    :loading="isSyncingResource(file)" :title="IsEngLish ? 'Fetch Google Drive file to LMS FileData' : 'Lấy file Google Drive vào LMS FileData'" :aria-label="IsEngLish ? 'Sync LMS FileData' : 'Đồng bộ LMS FileData'"
                                    @click="syncMissingLmsFileData('IMAGE', file)">
                                    <v-icon start size="14">mdi-file-cloud-outline</v-icon>{{ IsEngLish ? 'Sync FileData' : 'Đồng bộ FileData' }}
                                </v-btn>
                                <v-chip v-else-if="hasResourceNode(file)" size="x-small" color="warning" variant="tonal">{{ IsEngLish ? 'Missing LMS FileData' : 'Thiếu LMS FileData' }}</v-chip>
                                <v-btn class="media-card-delete" size="small" variant="text" color="error"
                                    @click="removeFile('image', index)" :aria-label="IsEngLish ? 'Delete image' : 'Xóa ảnh'">
                                    <v-icon size="17">mdi-close</v-icon>
                                </v-btn>
                            </div>
                        </div>
                    </div>
                    <div v-else class="assignment-media-empty"><v-icon size="30">mdi-image-off-outline</v-icon><span>{{ IsEngLish ? 'No images' : 'Chưa có hình ảnh' }}</span></div>

                    <div class="text-subtitle-2">{{ IsEngLish ? 'Attachments' : 'Tệp đính kèm' }}</div>
                    <div v-if="files.length" class="assignment-media-file-list">
                        <div v-for="(file, index) in files" :key="file.id || file.resourceFileId || index" class="assignment-media-file-card">
                            <div class="assignment-media-file-fallback">
                                <v-icon color="primary">mdi-file-outline</v-icon>
                                <a :href="fileSource(file)" target="_blank" rel="noopener" class="text-truncate">{{ file.name }}</a>
                                <v-btn :href="fileSource(file)" target="_blank" rel="noopener" icon="mdi-open-in-new"
                                    variant="tonal" size="x-small" color="primary" :title="IsEngLish ? 'Open file' : 'Mở file'" />
                            </div>
                            <div class="media-card-footer">
                                <span class="text-caption text-truncate">{{ file.name }} <small class="text-medium-emphasis">({{ formatFileSize(file.fileSize) }})</small></span>
                                <v-btn v-if="canSyncResource(file)" class="media-card-sync" size="x-small" variant="tonal" color="primary"
                                    :loading="isSyncingResource(file)" :title="IsEngLish ? 'Sync file to Resources' : 'Đồng bộ file vào Tài nguyên'" :aria-label="IsEngLish ? 'Sync file to Resources' : 'Đồng bộ file vào Tài nguyên'"
                                    @click="syncExistingResource('FILE', file)">
                                    <v-icon start size="14">mdi-cloud-sync-outline</v-icon>{{ IsEngLish ? 'Sync' : 'Đồng bộ' }}
                                </v-btn>
                                <v-chip v-else-if="isResourceSynced(file, 'FILE')" size="x-small" color="success" variant="tonal">{{ IsEngLish ? 'Synced' : 'Đã đồng bộ' }}</v-chip>
                                <v-btn v-else-if="canSyncLmsFileData(file)" class="media-card-sync" size="x-small" variant="tonal" color="warning"
                                    :loading="isSyncingResource(file)" :title="IsEngLish ? 'Fetch Google Drive file to LMS FileData' : 'Lấy file Google Drive vào LMS FileData'" :aria-label="IsEngLish ? 'Sync LMS FileData' : 'Đồng bộ LMS FileData'"
                                    @click="syncMissingLmsFileData('FILE', file)">
                                    <v-icon start size="14">mdi-file-cloud-outline</v-icon>{{ IsEngLish ? 'Sync FileData' : 'Đồng bộ FileData' }}
                                </v-btn>
                                <v-chip v-else-if="hasResourceNode(file)" size="x-small" color="warning" variant="tonal">{{ IsEngLish ? 'Missing LMS FileData' : 'Thiếu LMS FileData' }}</v-chip>
                                <v-btn class="media-card-delete" size="small" variant="text" color="error"
                                    @click="removeFile('file', index)" :aria-label="IsEngLish ? 'Delete file' : 'Xóa file'">
                                    <v-icon size="17">mdi-close</v-icon>
                                </v-btn>
                            </div>
                        </div>
                    </div>
                    <div v-else class="assignment-media-empty"><v-icon size="30">mdi-file-outline</v-icon><span>{{ IsEngLish ? 'No attachments' : 'Chưa có tệp đính kèm' }}</span></div>
                </div>
            </v-expansion-panel-text>
        </v-expansion-panel>
    </v-expansion-panels>
</template>

<script>
	export default {
		name: 'uc-media',
    props: { selectedData: Object, item: Object, loadingPage: Object },
    emits: ['update:selectedData'],
    data() {
        this.$i18n.locale = localStorage.getItem('IsLanguage') === 'true' ? 'en' : 'vi'
        return { isSaveFile: false, fileRecordAudio: null, mediaPanelOpen: null, syncingResourceKey: '' }
    },
    computed: {
        IsEngLish() {
            if (this.$i18n?.locale === 'en') return true
            try {
                const isLang = JSON.parse(localStorage.getItem('IsLanguage'))
                return isLang === true || isLang === 'true'
            } catch (e) {
                return localStorage.getItem('IsLanguage') === 'true'
            }
        },
        media() { return this.selectedData?.media || {} },
        images() { return this.media.sourceFiles?.image || [] },
        files() { return this.media.sourceFiles?.file || [] },
        hasYoutube() { return !!this.media.sourceYT?.source },
        hasAudio() { return !!this.media.sourceRecord?.source },
        hasFiles() { return this.images.length > 0 || this.files.length > 0 },
        hasMedia() { return this.hasYoutube || this.hasAudio || this.hasFiles },
        fileCount() { return this.images.length + this.files.length },
    },
    watch: {
        hasMedia: {
            immediate: true,
            handler(value) { this.mediaPanelOpen = value ? 0 : null }
        },
        selectedData: {
            deep: true,
            handler() { if (this.hasMedia) this.mediaPanelOpen = 0 }
        }
    },
    methods: {
        getUploadManager() { return window.UploadManager },
        sourceKey(source) { return String(source?.externalId || source?.id || source?.source || '') },
        // Video/audio là ô media đơn; upload lại phải dọn liên kết, node tài nguyên và file vật lý cũ
        // thành công trước khi bắt đầu upload bản mới. File/ảnh vẫn là danh sách nên được phép append.
        async clearExistingSingleMediaBeforeUpload(typeMedia) {
            if (typeMedia === 'YOUTUBE' && this.media.sourceYT?.source) {
                const removed = await this.removeSource(this.media.sourceYT, () => {
                    this.selectedData.media.sourceYT = { id: '', name: '', source: '' }
                })
                if (!removed) throw new Error('Không thể xóa video cũ trước khi tải video mới.')
                return
            }
            if ((typeMedia === 'RECORD_AUDIO' || typeMedia === 'UPLOAD_RECORD_AUDIO') && this.media.sourceRecord?.source) {
                const removed = await this.removeSource(this.media.sourceRecord, () => {
                    this.selectedData.media.sourceRecord = { id: '', name: '', source: '' }
                })
                if (!removed) throw new Error('Không thể xóa audio cũ trước khi tải audio mới.')
                return
            }
        },
        canSyncResource(source) {
            return Boolean(source && !source.resourceNodeId && (source.externalSource || source.externalId || source.source))
        },
        hasResourceNode(source) {
            return Boolean(source?.resourceNodeId)
        },
        hasLmsFileData(source) {
            // JSON cũ lưu LMS FileData ID ở id/source khi mediaSource = db.
            return Boolean(source?.dbFileId || source?.resourceFileId || (source?.mediaSource === 'db' && source?.id))
        },
        canSyncLmsFileData(source) {
            return Boolean(source?.resourceNodeId && !this.hasLmsFileData(source) && (source?.externalId || source?.externalSource || source?.source))
        },
        isResourceSynced(source, resourceType) {
            if (!source?.resourceNodeId) return false
            return resourceType === 'VIDEO' || this.hasLmsFileData(source)
        },
        isSyncingResource(source) { return this.syncingResourceKey === this.sourceKey(source) },
        getExistingDriveFileId(source) {
            const value = source?.externalId || source?.externalSource || source?.source || ''
            const match = String(value).match(/\/d\/([a-zA-Z0-9_-]+)|[?&]id=([a-zA-Z0-9_-]+)/)
            return match?.[1] || (source?.externalId ? String(source.externalId) : '')
        },
        resolveExistingResourceSource(source, resourceType) {
            const driveId = this.getExistingDriveFileId(source)
            const thirdPartySource = source?.externalSource || (resourceType === 'VIDEO' ? source?.source : '')
            if (thirdPartySource || driveId) {
                return {
                    id: driveId || source?.id,
                    source: thirdPartySource || (driveId ? `https://drive.google.com/file/d/${driveId}/preview` : source?.source),
                    mediaSource: 'upload',
                }
            }
            return {
                id: source?.id,
                source: source?.source,
                mediaSource: source?.mediaSource || 'db',
            }
        },
        async syncExistingResource(resourceType, source) {
            if (!this.canSyncResource(source)) return
            const assignmentID = this.assignmentId()
            if (!assignmentID) {
                Vue.$toast.warning('Vui lòng lưu bài tập trước khi đồng bộ media vào Tài nguyên.', { position: 'top' })
                return
            }
            const khoiID = Number(vueData?.assignment?.KhoiID || vueData?.KhoiID || 0)
            const monHocID = Number(vueData?.assignment?.MonHocID || vueData?.MonHocID || 0)
            if (!khoiID || !monHocID) {
                Vue.$toast.error('Bài tập chưa có đủ Khối/Môn để đồng bộ media vào Tài nguyên.', { position: 'top' })
                return
            }

            this.syncingResourceKey = this.sourceKey(source)
            try {
                const dbFileId = resourceType !== 'VIDEO'
                    ? (source?.dbFileId || (source?.mediaSource === 'db' ? source?.id : ''))
                    : ''
                const dbSource = resourceType !== 'VIDEO'
                    ? (source?.dbSource || (source?.mediaSource === 'db' ? source?.source : ''))
                    : ''
                const resourceSource = dbFileId || dbSource
                    ? { ...source, id: dbFileId, source: dbSource, mediaSource: 'db' }
                    : this.resolveExistingResourceSource(source, resourceType)
                if (!resourceSource.id && !resourceSource.source) throw new Error('Không tìm thấy URL hoặc mã file bên thứ ba')
                const metadata = {
                    uploadSource: resourceSource.mediaSource === 'db'
                        ? 'db'
                        : (/youtube\.com|youtu\.be/i.test(resourceSource.source || '') ? 'youtube' : 'gdrive'),
                    fileId: resourceSource.id || '',
                    fileName: source.name || 'Media bài tập',
                    contentType: source.contentType || '',
                    fileSize: Number(resourceSource.fileSize || source.fileSize || 0),
                    url: resourceSource.source || '',
                    ...(dbFileId || dbSource ? {
                        dbFileId,
                        dbSource,
                        storage: 'LMS_LHBS_FILEDATA',
                    } : {}),
                    ...(source?.externalId || source?.externalSource ? {
                        externalId: source.externalId || '',
                        externalUrl: source.externalSource || '',
                    } : {}),
                    origin: 'GIAO_BAI',
                    publishSource: resourceType,
                    assignmentID,
                    mediaContext: this.item,
                    syncedWithoutReupload: true,
                }
                const registered = await this.saveAssignmentResourceNode(metadata, khoiID, monHocID)
                source.resourceNodeId = registered.NoiDungID
                source.resourceLibraryId = registered.HocLieuID
                source.resourceFileId = source.resourceFileId || source.dbFileId || (source.mediaSource === 'db' ? source.id : '')
                source.resourceRegistrationPending = false
                this.emitUpdate()
                Vue.$toast.success('Đã đồng bộ media vào Tài nguyên mà không cần upload lại.', { position: 'top' })
            } catch (error) {
                console.error('Lỗi đồng bộ media bài tập vào tài nguyên:', error)
                Vue.$toast.error(error?.message || 'Không thể đồng bộ media vào Tài nguyên.', { position: 'top' })
            } finally {
                this.syncingResourceKey = ''
            }
        },
        async syncMissingLmsFileData(resourceType, source) {
            if (!this.canSyncLmsFileData(source)) return
            const assignmentID = this.assignmentId()
            if (!assignmentID) {
                Vue.$toast.warning('Vui lòng lưu bài tập trước khi đồng bộ LMS FileData.', { position: 'top' })
                return
            }
            const driveFileId = this.getExistingDriveFileId(source)
            if (!driveFileId) {
                Vue.$toast.error('Không lấy được Google Drive ID của file.', { position: 'top' })
                return
            }

            this.syncingResourceKey = this.sourceKey(source)
            try {
                const tokenResult = await fetchPromise('lms/FP_Youtube_Token_Get', {}, { forceRefresh: true, cache: false })
                const accessToken = tokenResult?.access_token
                if (!accessToken) throw new Error('Không lấy được quyền đọc file Google Drive')

                const driveResponse = await fetch(`https://www.googleapis.com/drive/v3/files/${encodeURIComponent(driveFileId)}?alt=media&supportsAllDrives=true`, {
                    headers: { Authorization: `Bearer ${accessToken}` }
                })
                if (!driveResponse.ok) throw new Error(`Không tải được file Google Drive (${driveResponse.status})`)

                const blob = await driveResponse.blob()
                if (!blob.size) throw new Error('File Google Drive rỗng hoặc không đọc được')
                const fileName = source.name || `media-${driveFileId}`
                const contentType = source.contentType || driveResponse.headers.get('content-type') || 'application/octet-stream'
                const file = new File([blob], fileName, { type: contentType })
                const uploadedDb = await this.uploadWithManager('uploadLmsSharedFile', file)
                const uploadedFile = uploadedDb?.Files?.[0]
                if (!uploadedFile?.FILE_ID) throw new Error('LMS FileData không trả về FILE_ID')

                source.dbFileId = uploadedFile.FILE_ID
                // Alias tương thích với SP SourceFile_GetAll và các page cũ.
                source.resourceFileId = uploadedFile.FILE_ID
                source.dbSource = uploadedFile.FILE_URL || `/FileData/${uploadedFile.FILE_ID}`
                source.dbMediaSource = 'db'
                source.fileSize = Number(uploadedFile.FILE_SIZE || file.size || source.fileSize || 0)
                source.contentType = uploadedFile.FILE_CONTENTTYPE || contentType
                source.resourceRegistrationPending = true
                this.emitUpdate()

                await this.registerResource(file, resourceType, source)
                source.resourceRegistrationPending = false
                this.emitUpdate()
                Vue.$toast.success('Đã lấy file Google Drive vào LMS FileData và cập nhật Tài nguyên.', { position: 'top' })
            } catch (error) {
                console.error('Lỗi đồng bộ Google Drive vào LMS FileData:', error)
                Vue.$toast.error(error?.message || 'Không thể đồng bộ file vào LMS FileData.', { position: 'top' })
            } finally {
                this.syncingResourceKey = ''
            }
        },
        assignmentId() { return Number(vueData?.AssignmentID || vueData?.assignment?.AssignmentID || 0) },
        async resolveAssignmentResourceLibrary(khoiID, monHocID) {
            const libraries = await fetchPromise('lms/FP_TaiNguyen_GetAll', {
                KhoiID: khoiID,
                MonHocID: monHocID,
                TaiNguyenLoaiID: 0,
                TaiNguyenMucID: 0,
            }, { forceRefresh: true, useStaleCacheOnError: false })
            const library = (libraries || []).find(item => item.TaiNguyenLoaiCode === 'TAI_LIEU_THAM_KHAO')
            if (!library?.HocLieuID) throw new Error('Không xác định được bộ tài nguyên của Khối/Môn hiện tại')
            return library.HocLieuID
        },
        async saveAssignmentResourceNode(metadata, khoiID, monHocID) {
            const hocLieuID = await this.resolveAssignmentResourceLibrary(khoiID, monHocID)
            const response = await fetchPromise('lms/FP_TaiNguyen_Node_Save', {
                NoiDungID: 0,
                HocLieuID: hocLieuID,
                ParentID: null,
                TenNoiDung: metadata.fileName,
                LoaiNoiDung: metadata.publishSource,
                NguonTaiNguyenCode: 'GIAO_BAI',
                NguonResourceType: 'ASSIGNMENT',
                NguonResourceID: metadata.assignmentID,
                ThuTu: 0,
                User: vueData?.user?.UserID || '',
                DataJson: JSON.stringify(metadata),
            }, { cache: false })
            const registered = Array.isArray(response) ? response[0] : response
            if (!registered?.NoiDungID) throw new Error('API tài nguyên không trả về NoiDungID')
            return { ...registered, HocLieuID: hocLieuID }
        },
        async handleInputChange(event, type) {
            const file = event?.target?.files?.[0]
            if (event?.target) event.target.value = ''
            await this.handleFileChange(file, type)
        },
        async handleFileChange(file, typeMedia) {
            if (!file) return
            try {
                const manager = this.getUploadManager()
                if (!manager) throw new Error('UploadManager chưa được khởi tạo')
                if (typeMedia === 'YOUTUBE') {
                    await this.clearExistingSingleMediaBeforeUpload(typeMedia)
                    const uploaded = await this.uploadWithManager('uploadLmsYoutube', file, {
                        playlistName: `LMS_Assignment_${this.assignmentId()}`,
                        title: file.name.replace(/\.[^/.]+$/, '')
                    })
                    this.selectedData.media.sourceYT = {
                        ...uploaded,
                        fileSize: file.size,
                        contentType: file.type || 'video/*',
                        mediaSource: 'upload',
                        mediaProvider: 'youtube',
                        videoId: uploaded.id,
                        resourceRegistrationPending: true,
                    }
                    this.emitUpdate()
                    this.registerResourceInBackground(file, 'VIDEO', this.selectedData.media.sourceYT)
                } else if (typeMedia === 'FILE') {
                    const isImage = file.type.startsWith('image/')
                    const allowed = isImage || ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation'].includes(file.type)
                    if (!allowed) throw new Error('Chỉ hỗ trợ hình ảnh, PDF, Word và PowerPoint')
                    // Lưu hai nơi: Drive dùng làm URL hiển thị, FileData dùng cho tài nguyên LMS.
                    const uploadedDb = await this.uploadWithManager('uploadLmsSharedFile', file)
                    const uploadedFile = uploadedDb?.Files?.[0]
                    if (!uploadedFile?.FILE_ID) throw new Error('API lưu trữ không trả về FILE_ID')

                    let uploadedExternal
                    try {
                        uploadedExternal = await this.uploadWithManager('uploadLmsGoogleDrive', file, {
                            folderPath: `LMS_Assignment/Assignment_${this.assignmentId()}/${vueData?.user?.UserID || ''}`
                        })
                    } catch (error) {
                        await this.getUploadManager().deleteLmsFileData(uploadedFile.FILE_ID).catch(() => {})
                        throw error
                    }

                    const source = {
                        id: uploadedFile.FILE_ID,
                        name: uploadedExternal?.name || uploadedFile.FILE_NAME || file.name,
                        source: uploadedFile.FILE_URL || `/FileData/${uploadedFile.FILE_ID}`,
                        fileSize: Number(uploadedFile.FILE_SIZE || file.size || 0),
                        contentType: uploadedFile.FILE_CONTENTTYPE || file.type || '',
                        mediaSource: 'db',
                        dbFileId: uploadedFile.FILE_ID,
                        resourceFileId: uploadedFile.FILE_ID,
                        dbSource: uploadedFile.FILE_URL || `/FileData/${uploadedFile.FILE_ID}`,
                        dbMediaSource: 'db',
                        externalId: uploadedExternal?.id || '',
                        externalSource: uploadedExternal?.source || '',
                        externalMediaSource: 'upload',
                        resourceRegistrationPending: true,
                    }
                    if (!this.media.sourceFiles) this.media.sourceFiles = { file: [], image: [] }
                    if (!Array.isArray(this.media.sourceFiles[isImage ? 'image' : 'file'])) this.media.sourceFiles[isImage ? 'image' : 'file'] = []
                    this.media.sourceFiles[isImage ? 'image' : 'file'].push(source)
                    this.emitUpdate()
                    this.registerResourceInBackground(file, isImage ? 'IMAGE' : 'FILE', source)
                } else if (typeMedia === 'RECORD_AUDIO' || typeMedia === 'UPLOAD_RECORD_AUDIO') {
                    await this.clearExistingSingleMediaBeforeUpload(typeMedia)
                    const uploadedDb = await this.uploadWithManager('uploadLmsSharedFile', file)
                    const uploadedFile = uploadedDb?.Files?.[0]
                    if (!uploadedFile?.FILE_ID) throw new Error('API lưu trữ audio không trả về FILE_ID')
                    let uploadedExternal = null
                    try {
                        uploadedExternal = await this.uploadWithManager('uploadLmsGoogleDrive', file, { folderPath: `LMS_Assignment/Assignment_${this.assignmentId()}/${vueData?.user?.UserID || ''}` })
                    } catch (error) {
                        console.warn('Audio đã lưu LMS-LHBS-file nhưng chưa upload được Google Drive:', error)
                    }
                    this.selectedData.media.sourceRecord = {
                        id: uploadedExternal?.id || uploadedFile.FILE_ID,
                        name: uploadedExternal?.name || uploadedFile.FILE_NAME || file.name,
                        source: uploadedExternal?.source || uploadedFile.FILE_URL || `/FileData/${uploadedFile.FILE_ID}`,
                        fileSize: Number(uploadedFile.FILE_SIZE || file.size || 0),
                        contentType: uploadedFile.FILE_CONTENTTYPE || file.type || '',
                        mediaSource: uploadedExternal ? 'upload' : 'db',
                        dbFileId: uploadedFile.FILE_ID,
                        resourceFileId: uploadedFile.FILE_ID,
                        dbSource: uploadedFile.FILE_URL || `/FileData/${uploadedFile.FILE_ID}`,
                        dbMediaSource: 'db',
                        externalId: uploadedExternal?.id || '',
                        externalSource: uploadedExternal?.source || '',
                        externalMediaSource: uploadedExternal ? 'upload' : '',
                        resourceRegistrationPending: true,
                    }
                    this.isSaveFile = true
                    this.emitUpdate()
                    this.registerResourceInBackground(file, 'AUDIO', this.selectedData.media.sourceRecord)
                }
                this.emitUpdate()
            } catch (error) {
                console.error('Lỗi upload media bài tập:', error)
                Vue.$toast.error(error?.message || 'Không thể tải media lên', { position: 'top' })
            }
        },
        deleteExternalWithManager(manager, method, fileId, accessToken) {
            // UploadManager cũ có thể nuốt lỗi của Drive/YouTube; bọc callback thành Promise
            // để luồng thay media chỉ tiếp tục khi API xác nhận xóa thành công.
            return new Promise((resolve, reject) => manager[method](fileId, {
                accessToken,
                onComplete: resolve,
                onError: reject,
            }))
        },
        uploadWithManager(method, file, options) {
            return new Promise((resolve, reject) => this.getUploadManager()[method](file, { ...options, onComplete: resolve, onError: reject }))
        },
        registerResourceInBackground(file, resourceType, source) {
            this.registerResource(file, resourceType, source).catch(error => {
                if (source) source.resourceRegistrationPending = true
                this.emitUpdate()
                console.error('Lỗi bổ sung media bài tập vào tài nguyên:', error)
                Vue.$toast.warning('Media đã được thêm vào bài tập nhưng chưa bổ sung được vào tài nguyên.', { position: 'top' })
            })
        },
        async registerResource(file, resourceType, source) {
            const assignmentID = this.assignmentId()
            if (!assignmentID) {
                if (source) source.resourceRegistrationPending = true
                Vue.$toast.warning('Bài tập chưa có mã, file sẽ được bổ sung vào tài nguyên sau khi lưu bài.', { position: 'top' })
                return
            }
            // UI dùng source bên thứ ba, còn tài nguyên LMS phải trỏ về bản FileData.
            const resourceSource = source?.dbFileId
                ? {
                    ...source,
                    id: source.dbFileId,
                    source: source.dbSource,
                    mediaSource: source.dbMediaSource || 'db',
                }
                : source
            const metadata = {
                uploadSource: resourceSource.mediaSource === 'db' ? 'db' : (resourceSource.mediaSource === 'upload' && resourceSource.source?.includes('youtube.com') ? 'youtube' : 'gdrive'),
                fileId: resourceSource.id,
                fileName: source.name || file.name,
                contentType: file.type || '',
                fileSize: Number(resourceSource.fileSize || file.size || 0),
                url: resourceSource.source,
                ...(source?.dbFileId ? {
                    dbFileId: source.dbFileId,
                    resourceFileId: source.resourceFileId || source.dbFileId,
                    dbSource: source.dbSource || `/FileData/${source.dbFileId}`,
                    storage: 'LMS_LHBS_FILEDATA',
                } : {}),
                ...(source?.externalId || source?.externalSource ? {
                    externalId: source.externalId || '',
                    externalUrl: source.externalSource || '',
                } : {}),
                origin: 'GIAO_BAI',
                publishSource: resourceType,
                assignmentID,
                mediaContext: this.item,
            }
            const khoiID = Number(vueData?.assignment?.KhoiID || vueData?.KhoiID || 0)
            const monHocID = Number(vueData?.assignment?.MonHocID || vueData?.MonHocID || 0)
            if (!khoiID || !monHocID) throw new Error('Bài tập chưa có đủ Khối/Môn để lưu tài nguyên')
            const registered = await this.saveAssignmentResourceNode(metadata, khoiID, monHocID)
            source.resourceNodeId = registered.NoiDungID
            source.resourceLibraryId = registered.HocLieuID
            source.resourceFileId = source.resourceFileId || source.dbFileId || (source.mediaSource === 'db' ? source.id : '')
            source.resourceRegistrationPending = false
            this.emitUpdate()
        },
        async removeYoutube() { await this.removeSource(this.media.sourceYT, () => { this.selectedData.media.sourceYT = { id: '', name: '', source: '' } }) },
        async removeAudio() { await this.removeSource(this.media.sourceRecord, () => { this.selectedData.media.sourceRecord = { id: '', name: '', source: '' } }) },
        async removeFile(type, index) { const source = this.media.sourceFiles[type][index]; await this.removeSource(source, () => this.media.sourceFiles[type].splice(index, 1)) },
        async removeSource(source, removeLocal) {
            try {
                this.setLoading(true, 'Đang xóa media...')
                const manager = this.getUploadManager()
                // Xóa node tài nguyên trước để không còn node trỏ tới file đã bị xóa.
                if (source?.resourceNodeId) {
                    await fetchPromise('lms/FP_TaiNguyen_Node_Delete', { NoiDungID: source.resourceNodeId }, { cache: false })
                }
                // Video upload thuộc YouTube; audio/file upload thuộc Google Drive.
                // Phải chọn đúng provider để không gửi videoId sang API xóa Drive.
                const sourceUrl = source?.externalSource || source?.source || ''
                const isYoutubeSource = source?.mediaProvider === 'youtube'
                    || (source?.mediaSource === 'upload' && /youtube\.com|youtu\.be/i.test(sourceUrl))
                const externalId = source?.externalId || (source?.mediaSource === 'upload' ? source.id : '')
                if (isYoutubeSource && externalId) {
                    const token = await fetchPromise('lms/FP_Youtube_Token_Get', {}, { forceRefresh: true, cache: false })
                    await this.deleteExternalWithManager(manager, 'deleteFromYouTube', externalId, token?.access_token)
                } else if (externalId) {
                    const token = await fetchPromise('lms/FP_Youtube_Token_Get', {}, { forceRefresh: true, cache: false })
                    await this.deleteExternalWithManager(manager, 'deleteFromGoogleDrive', externalId, token?.access_token)
                }
                if (!source?.resourceNodeId) {
                    // Khi không có node tài nguyên cũ, dọn trực tiếp LMS FileData sau khi đã xóa Drive.
                    if (source?.id && source.mediaSource === 'db') {
                        await manager.deleteLmsFileData(source.id)
                    }
                    if (source?.dbFileId && source.dbFileId !== source.id) {
                        await manager.deleteLmsFileData(source.dbFileId)
                    }
                    if (source?.resourceFileId) {
                        // Tương thích dữ liệu cũ từng lưu bản sao vào FileData.
                        await manager.deleteLmsFile(source.resourceFileId)
                    }
                }
                removeLocal()
                this.emitUpdate()
                return true
            } catch (error) {
                console.error('Lỗi xóa media bài tập:', error)
                Vue.$toast.error(error?.message || 'Không thể xóa media', { position: 'top' })
                return false
            } finally { this.setLoading(false) }
        },
        setLoading(value, text = '') { if (this.loadingPage) { this.loadingPage.isLoading = value; if (text) this.loadingPage.text = text } },
        emitUpdate() { this.$emit('update:selectedData', this.selectedData) },
        fileSource(file) {
            const source = file?.externalSource || file?.source || ''
            if (!source) return source
            if (/^https?:\/\/lms\.lhbs\.vn\/FileData\//i.test(source)) {
                return source.replace(/^https?:\/\/lms\.lhbs\.vn\/FileData\//i, 'https://file.lhbs.vn/lms/FileData/')
            }
            if (/^https?:\/\//i.test(source)) return source
            if (file?.mediaSource !== 'db') return source
            const base = vueData?.v_Set?.urlReadFile || ''
            return base ? `${base.replace(/\/+$/, '')}/${source.replace(/^\/+/, '')}` : source
        },
        imageSource(file) {
            const source = file?.externalSource || file?.source || ''
            return source?.includes('drive.google.com')
                ? `https://drive.google.com/thumbnail?id=${file.externalId || file.id || this.getDriveFileId(source)}&sz=w1000`
                : this.fileSource(file)
        },
        getDriveFileId(url) {
            const match = String(url || '').match(/\/d\/([^/]+)|[?&]id=([^&]+)/)
            return match?.[1] || match?.[2] || null
        },
        formatFileSize(size) {
            const value = Number(size || 0)
            if (!value) return '—'
            if (value < 1024) return `${value} B`
            if (value < 1024 * 1024) return `${(value / 1024).toFixed(1)} KB`
            return `${(value / (1024 * 1024)).toFixed(1)} MB`
        },
        renderUrlYoutube,
    }
	}
</script>
<template>
	<v-chip v-if="hasFile" :color="color" :class="textColor" outlined label hide-details>
		<v-icon left size="16">{{ icon }}</v-icon>
		<a :class="[textColor, 'text-decoration-none', 'font-weight-bold']" :href="fullUrl" :target="target">
			{{ label }}
		</a>
	</v-chip>
	<v-chip v-else color="grey-lighten-4" class="text-grey" outlined label hide-details>
		{{ emptyLabel }}
	</v-chip>
</template>

<script>
	export default {
		name: "c-chip-file",
		props: {
			url: {
				type: String,
				default: "",
			},
			fileId: {
				type: [String, Number],
				default: "",
			},
			prefix: {
				type: String,
				default: "",
			},
			label: {
				type: String,
				default: "Xem file",
			},
			emptyLabel: {
				type: String,
				default: "Chưa có file",
			},
			color: {
				type: String,
				default: "deep-purple-lighten-5",
			},
			textColor: {
				type: String,
				default: "text-deep-purple",
			},
			icon: {
				type: String,
				default: "mdi-file-check-outline",
			},
			target: {
				type: String,
				default: "_blank",
			},
		},
		computed: {
			baseUrl() {
				return window.vueData?.v_Set?.urlReadFile || "";
			},
			hasFile() {
				return Boolean(this.url || this.fileId);
			},
			fullUrl() {
				if (this.url) {
					if (this.url.startsWith("http://") || this.url.startsWith("https://")) {
						return this.url;
					}
					const cleanBase = this.baseUrl
						? this.baseUrl.endsWith("/")
							? this.baseUrl
							: this.baseUrl + "/"
						: "";
					const cleanUrl = this.url.startsWith("/") ? this.url.slice(1) : this.url;
					return cleanBase + cleanUrl;
				}
				if (this.fileId) {
					const cleanBase = this.baseUrl
						? this.baseUrl.endsWith("/")
							? this.baseUrl
							: this.baseUrl + "/"
						: "";
					const pref = this.prefix || "FileData/";
					const cleanPref = pref.startsWith("/") ? pref.slice(1) : pref;
					const cleanPrefWithSlash = cleanPref.endsWith("/") ? cleanPref : cleanPref + "/";
					return cleanBase + cleanPrefWithSlash + this.fileId;
				}
				return "#";
			},
		},
	}
</script>
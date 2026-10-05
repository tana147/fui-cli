Vue.component("uc-setting-rating", {
    props: [''],
    data() {
        return {
        };
    },
    computed: {
    },
    methods: {
    },
    mounted() {
        this.autoPaginate();
    },
    beforeDestroy() {
        clearInterval(this.intervalId);
    },
    template: /*html*/ `
        <div style="color:#fff; font-weight:bold">
        </div>
    `,
});
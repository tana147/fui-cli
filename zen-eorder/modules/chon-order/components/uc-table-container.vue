<template>
    <div class="my-4 list-flex-wrap-center">
        <template v-for="item in list" :key="item.BanID">
            <uc-table :item="item" />
        </template>
    </div>
</template>

<script>
export default {
    props: ["list"],
}
</script>

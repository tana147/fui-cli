<template>
    <v-row class="v-toolbar__title white--text">
        <v-col cols="2" class="d-flex align-center">
            <v-icon @click="window.location.href = '/'" class="float-left px-3" color="white">mdi-home</v-icon>
        </v-col>
        <v-col cols="8" class="d-flex align-center justify-center">ZEN EORDER - MPOS</v-col>
        <v-col cols="2" class="d-flex align-center justify-end">
            <fp-profile color="white" urlSignout="https://login.zenfoodcourt.vn/signout" urlChangePassword="https://login.zenfoodcourt.vn/ChangePassword" />
        </v-col>
    </v-row>
</template>

<script>
export default {}
</script>

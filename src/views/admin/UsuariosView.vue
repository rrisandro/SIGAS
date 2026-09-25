<template>
  <div class="admin-page">
    <header class="header-banner">
      <div>
        <div class="badge">Seguridad y Permisos</div>
        <h1>Control de Usuarios y Roles</h1>
        <p>Administración de niveles de acceso del sistema</p>
      </div>
    </header>

    <div class="table-card">
      <div v-if="loading" class="loading-state"><div class="spinner"></div>Cargando usuarios...</div>
      
      <div v-else class="table-wrapper">
        <table class="custom-table">
          <thead>
            <tr>
              <th>Cédula</th>
              <th>Nombre</th>
              <th>Cargo / Rol</th>
              <th>Acción</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="user in usuarios" :key="user.id">
              <td class="id-cell">V-{{ user.id }}</td>
              <td>{{ user.nombre_familia }}</td>
              <td>
                <select 
                  :value="user.id_cargo" 
                  @change="cambiarCargo(user.id, $event.target.value)"
                  class="select-cargo"
                >
                  <option value="1">1 - Administrador</option>
                  <option value="2">2 - Jefe de Calle</option>
                  <option value="3">3 - Familia</option>
                </select>
              </td>
              <td>
                <span class="status-ok">Registrado</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../../composables/supabase.js'

const usuarios = ref([])
const loading = ref(true)

async function cargarUsuarios() {
  loading.value = true
  const { data } = await supabase.from('familias').select('*')
  if (data) usuarios.value = data
  loading.value = false
}

async function cambiarCargo(idFamilia, nuevoCargoId) {
  await supabase
    .from('familias')
    .update({ id_cargo: parseInt(nuevoCargoId) })
    .eq('id', idFamilia)
}

onMounted(cargarUsuarios)
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600&display=swap');
.admin-page { font-family: 'Poppins', sans-serif; color: #fff; padding: 1.5rem; display: flex; flex-direction: column; gap: 1.5rem; }
.header-banner { background: linear-gradient(135deg, rgba(0, 114, 206, 0.4), rgba(255, 122, 0, 0.2)); backdrop-filter: blur(16px); border: 1px solid rgba(0, 114, 206, 0.4); border-radius: 20px; padding: 1.8rem 2rem; }
.badge { display: inline-block; background: rgba(0, 114, 206, 0.3); color: #38b6ff; border: 1px solid rgba(56, 182, 255, 0.4); padding: 4px 12px; border-radius: 20px; font-size: 0.75rem; font-weight: 600; margin-bottom: 0.5rem; }
.header-banner h1 { margin: 0; font-size: 1.6rem; }
.header-banner p { margin: 0.3rem 0 0 0; color: #a0aec0; font-size: 0.9rem; }
.table-card { background: rgba(15, 23, 36, 0.75); backdrop-filter: blur(16px); border: 1px solid rgba(50, 132, 209, 0.3); border-radius: 20px; padding: 1.5rem; }
.custom-table { width: 100%; border-collapse: collapse; text-align: left; }
.custom-table th { padding: 0.8rem 1rem; font-size: 0.8rem; color: #a0aec0; border-bottom: 1px solid rgba(255, 255, 255, 0.1); }
.custom-table td { padding: 1rem; border-bottom: 1px solid rgba(255, 255, 255, 0.05); }
.id-cell { font-weight: 600; color: #38b6ff; }
.select-cargo { background: #0f1724; border: 1px solid rgba(0, 114, 206, 0.5); color: #fff; padding: 6px 10px; border-radius: 8px; outline: none; font-family: 'Poppins', sans-serif; }
.status-ok { color: #4ade80; font-size: 0.8rem; }
.loading-state { text-align: center; padding: 3rem; color: #a0aec0; }
.spinner { width: 30px; height: 30px; border: 3px solid rgba(255, 255, 255, 0.1); border-top-color: #0072ce; border-radius: 50%; animation: spin 1s infinite linear; margin: 0 auto 0.5rem auto; }
@keyframes spin { 100% { transform: rotate(360deg); } }
</style>
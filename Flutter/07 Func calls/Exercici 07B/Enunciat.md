<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="../assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

# Gestió del Proxmox amb IA

Afegeix una eina de Xat per IA a la eina de gestió del proxmox, per tal que fent servir **function calls** poguis fer totes les accions de manera conversacional.

Fes servir l'exemple 0700 com a base inicial, veuràs que l'exemple manté una llista de polígons que cal dibuixar i les seves propietats.

## Fase 1

S'ha de poder:

- Afegir/Esborrar servidors coneguts
- Canviar configuracions de l'arxiu *.json*
- Mostrar la pantalla de carpetes i arxius i entrar dins de carpetes
- Afegir/Esborrar arxius i carpetes
- Mostrar la informació d'arxius
- Descarregar arxius remots

## Fase 2

S'ha de poder:

- Canviar estat de servidors remots (funcionant/aturats)
- Activar redirecció de port 80 cap a servidors remots
- Mostrar i navegar per l'arbre de carpetes estil *"baobab"*


;-------------------------------------------------------
.MEMORYMAP                      
  SLOTSIZE    $10000
  DEFAULTSLOT 0                 
  SLOT        0 $0000           
.ENDME          

.ROMBANKSIZE  $10000              
.ROMBANKS     4 
;-------------------------------------------------------                  

;-------------------------------------------------------
.SNESHEADER
  ID "SNES"                     
  
  NAME "SNES INIT HIROM!!!!!!"  
  ;    "123456789012345678901"  


  SLOWROM
  HIROM

  CARTRIDGETYPE   $00               
  ROMSIZE         $08              
  SRAMSIZE        $00             
  COUNTRY         $01             
  LICENSEECODE    $00                
  VERSION         $00                   
.ENDSNES
;-------------------------------------------------------

;-------------------------------------------------------
.SNESNATIVEVECTOR            
  COP     EmptyHandler
  BRK     EmptyHandler
  ABORT   EmptyHandler
  NMI     EmptyHandler
  IRQ     EmptyHandler
.ENDNATIVEVECTOR

.SNESEMUVECTOR              
  COP     EmptyHandler
  ABORT   EmptyHandler
  NMI     EmptyHandler
  RESET   Start
  IRQBRK  EmptyHandler
.ENDEMUVECTOR
;-------------------------------------------------------

;-------------------------------------------------------
.BANK 0 SLOT 0
.ORG $F000      
.SECTION "EmptyVectors" SEMIFREE
EmptyHandler:
        rti

.ENDS
;-------------------------------------------------------

.EMPTYFILL $FF
-- Operasjon
EXEC RenameVar 8192,'HrAktuellOpr'
EXEC RenameVar 8193,'HrSide'
EXEC RenameVar 8195,'HrOprDato'
EXEC RenameVar 8197,'HrOprTidspunkt'

-- Bruddtidspunkt
EXEC RenameVar 8194,'HrBruddDato'
EXEC RenameVar 8196,'HrBruddTidspunkt' /* BruddTidspunkt */
EXEC RenameVar 8199,'HrBruddTilOpr'

-- Komorbiditet
EXEC RenameVar 8200,'HrDemens'
EXEC RenameVar 8201,'HrAsaKlasse'

-- Type Primærbrudd
EXEC RenameVar 8202,'HrPriBruddType'
EXEC RenameVar 8203,'HrPriBruddTypeAnnet'

-- Type Primæroperasjon
EXEC RenameVar 8204,'HrPriOprType' /* HoftePrimOp */
EXEC RenameVar 8205,'HrPriOprTypeAnnet'

-- Årsaker til reoperasjon
EXEC RenameVar 8206,'HrReGrSyntesesvikt'
EXEC RenameVar 8207,'HrReGrIkkeHelet'
EXEC RenameVar 8208,'HrReGrCaputNekrose'
EXEC RenameVar 8209,'HrReGrLokalSmerte'
EXEC RenameVar 8210,'HrReGrFeilstilling'
EXEC RenameVar 8211,'HrReGrInfOverfladisk'
EXEC RenameVar 8212,'HrReGrInfDyp'
EXEC RenameVar 8213,'HrReGrHematom'
EXEC RenameVar 8214,'HrReGrLuksasjon'
EXEC RenameVar 8215,'HrReGrCaputSkade'
EXEC RenameVar 8216,'HrReGrNyttBrudd'
EXEC RenameVar 8217,'HrReGrLosning'
EXEC RenameVar 8218,'HrReGrAnnet'
EXEC RenameVar 8219,'HrReGrAnnetTekst'

EXEC RenameVar 8220,'HrReTyFjerning'
EXEC RenameVar 8221,'HrReTyGirdlestone'
EXEC RenameVar 8222,'HrReTyBipolar'  /* HrSekHemiBipolar */
EXEC RenameVar 8223,'HrReTyUnipolar' /* HrSekHemiUnipolar */
EXEC RenameVar 8224,'HrReTyResyntese'
EXEC RenameVar 8225,'HrReTyDebridement'
EXEC RenameVar 8226,'HrReTyReposLukket'
EXEC RenameVar 8227,'HrReTyReposApen'
EXEC RenameVar 8228,'HrReTyAnnet'
EXEC RenameVar 8229,'HrReTyAnnetTekst'

-- Fiksasjon
EXEC RenameVar 8230,'HrHemiSement'
EXEC RenameVar 8292,'HrHemiHA'
EXEC RenameVar 8231,'HrHemiSementNavn'

EXEC RenameVar 8232,'HrPatoBrudd'
EXEC RenameVar 8233,'HrPatoBruddTekst'

-- Tilgang og anestesi
EXEC RenameVar 8234,'HrTilgang'
EXEC RenameVar 8287,'HrTilgangAnnen'
EXEC RenameVar 8235,'HrAnestesi'
EXEC RenameVar 8236,'HrAnestesiAnnen'

EXEC RenameVar 8237,'HrKompl'
EXEC RenameVar 8238,'HrKomplTekst'
EXEC RenameVar 8239,'HrOperasjonTid'

EXEC RenameVar 8243,'HrAbMed1Varighet'
EXEC RenameVar 8246,'HrAbMed2Varighet'
EXEC RenameVar 8249,'HrAbMed3Varighet'

-- Tromboseprofylakse 
EXEC RenameVar 8288,'HrTrombForsteDose'
EXEC RenameVar 8252,'HrTromb1DssnOpDag'
EXEC RenameVar 8253,'HrTromb1DssnVidere'
EXEC RenameVar 8255,'HrTromb2DssnOpDag'
EXEC RenameVar 8256,'HrTromb2DssnVidere'
EXEC RenameVar 8258,'HrFibrinGitt'
EXEC RenameVar 8259,'HrFibrinNavn'
EXEC RenameVar 8260,'HrFibrinDssn'

-- Operatørefaring
EXEC RenameVar 8261,'HrKirurgErfaring'
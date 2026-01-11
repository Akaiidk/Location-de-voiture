-- Base de donnée : ProjetBDD

-- Affichage des "PUT_LINE" avec le client SQLDeveloper : 
SET SERVEROUTPUT ON
-- Mettre la date en Format Français pour les logiciels avec un autre format
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Suppression des objets
-- Suppression des tables et des contraintes associées
 DROP TABLE Tarif CASCADE CONSTRAINTS;
 DROP TABLE Location CASCADE CONSTRAINTS;
 DROP TABLE Formules CASCADE CONSTRAINTS;
 DROP TABLE Vehicule CASCADE CONSTRAINTS;
 DROP TABLE Modeles CASCADE CONSTRAINTS;
 DROP TABLE Types CASCADE CONSTRAINTS;

 DROP SEQUENCE seqVehicule;
 DROP SEQUENCE seqLocation;

 DROP PROCEDURE AjouterVehicule;
 DROP PROCEDURE LouerVehicule;
 DROP PROCEDURE VehiculesDisponibles;
 DROP PROCEDURE RetournerVehicule;
 DROP FUNCTION ChiffreAffaires;
 DROP FUNCTION FormuleAvantageuse;

-- a) Création des tables
CREATE TABLE Types ( IdType NUMBER(3) PRIMARY KEY,
            Type VARCHAR2(15)
            );
            
CREATE TABLE Modeles ( 	Modele VARCHAR2(15) PRIMARY KEY, 
			Marque VARCHAR2(15) NOT NULL,
			IdType Number(3) NOT NULL,
            FOREIGN KEY (IdType) REFERENCES Types(IdType)
			);
			 
CREATE TABLE Vehicule ( NumVehicule Number(3) PRIMARY KEY,
            Modele VARCHAR2(15) NOT NULL,
            Matricule CHAR(7),
            DateMatricule DATE,
            Kilometrage NUMBER(5),
            Situation VARCHAR2(15),
            FOREIGN KEY (Modele) REFERENCES Modeles(Modele)
            );

CREATE TABLE Formules ( Formule VARCHAR2(15) PRIMARY KEY,
            NbJours NUMBER(3),
            KmMax NUMBER(5)
			 );
             
CREATE TABLE Location ( NumLocation NUMBER(5) PRIMARY KEY,
            NumVehicule NUMBER(3),
            Formule VARCHAR(15),
            DateDepart DATE,
            DateRetour DATE,
            NbKm NUMBER(5),
            Montant NUMBER(7),
            FOREIGN KEY (NumVehicule) REFERENCES Vehicule(NumVehicule),
            FOREIGN KEY (Formule)  REFERENCES Formules(Formule)
            );

CREATE TABLE Tarif ( 
            IdType NUMBER(3),
            Formule VARCHAR(15),
            Prix Number(6),
            PrixKmSupp NUMBER(2,2),
            FOREIGN KEY (IdType) REFERENCES Types(IdType),
            FOREIGN KEY (Formule) REFERENCES Formules(Formule),
            PRIMARY KEY (IdType,Formule)
            );
        
-- Création de la séquence seqVehicule pour NumVehicule
CREATE SEQUENCE seqVehicule START WITH 1 INCREMENT BY 1; 

-- Création de la séquence seqLocation pour NumLocation
CREATE SEQUENCE seqLocation START WITH 1 INCREMENT BY 1; 

--Procédure AjouterVehicule TOM
CREATE OR REPLACE PROCEDURE AjouterVehicule(Model in varchar2, Mat in char, DateMat in date, Km in number)
IS
  v_nombreModeleExistant NUMBER;
  v_nombreMatriculeExistant NUMBER;
  parametre_manquant EXCEPTION;
  km_negatif EXCEPTION;
  modele_inexistant EXCEPTION;
BEGIN
 IF Model IS NULL OR Mat IS NULL OR DateMat IS NULL OR Km IS NULL THEN RAISE parametre_manquant; END IF;
 
 IF Km < 0 THEN RAISE km_negatif; END IF;
 
 SELECT COUNT(Modele) INTO v_nombreModeleExistant FROM Modeles WHERE Modele = Model ;
 IF v_nombreModeleExistant = 0 THEN RAISE modele_inexistant ; END IF;
 
 SELECT COUNT(Matricule) INTO v_nombreMatriculeExistant FROM Vehicule WHERE Matricule = Mat;
 IF v_nombreMatriculeExistant = 1 THEN
   UPDATE Vehicule
   SET Modele = Model,
     DateMatricule = DateMat,
     Kilometrage = Km
   WHERE Matricule = Mat;
 ELSE 
    INSERT INTO Vehicule (NumVehicule, Modele, Matricule, DateMatricule, Kilometrage, Situation) 
    VALUES (seqVehicule.NEXTVAL,Model,Mat,DateMat,Km,'disponible');
 END IF;

EXCEPTION
  WHEN parametre_manquant THEN
    DBMS_OUTPUT.PUT_LINE('parametre manquant');
  WHEN km_negatif THEN
    DBMS_OUTPUT.PUT_LINE('kilometrage negatif');
  WHEN modele_inexistant THEN
    DBMS_OUTPUT.PUT_LINE('modele inexistant');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erreur Oracle dans AjouterVehicule : '||sqlcode||' ; Message Oracle : '||sqlerrm);
END;
/
--Procédure LouerVehicule HUGO
CREATE OR REPLACE PROCEDURE LouerVehicule(NumVeh in number, Formul in varchar2, Depart in date)
IS
  v_situation Vehicule.Situation%TYPE;
  v_nombreVehicule NUMBER;
  v_nombreFormule NUMBER;
  v_nombreJourLocation NUMBER;
  v_dateRetour DATE;
  vehicule_non_disponible EXCEPTION;
  vehicule_innexistant EXCEPTION;
  formule_innexistante EXCEPTION;
  parametre_manquant EXCEPTION;
  depart_incorrect EXCEPTION;
BEGIN
  IF NumVeh IS NULL OR Formul IS NULL OR Depart IS NULL THEN RAISE parametre_manquant; END IF;
  
  SELECT Count(NumVehicule) INTO v_nombreVehicule FROM Vehicule WHERE NumVehicule = NumVeh;
  IF v_nombreVehicule = 0 THEN RAISE vehicule_innexistant; END IF;
  
  SELECT Situation INTO v_situation FROM Vehicule WHERE NumVehicule = NumVeh;
  IF v_situation != 'disponible' THEN RAISE vehicule_non_disponible; END IF;
  
  SELECT Count(Formule) INTO v_nombreFormule FROM Formules WHERE Formule = Formul;
  IF v_nombreFormule = 0 THEN RAISE formule_innexistante; END IF;
  
  IF Depart < SYSDATE THEN RAISE depart_incorrect; END IF;

  SELECT Nbjours INTO v_nombreJourLocation FROM Formules WHERE Formule = Formul;
  v_dateRetour := Depart + v_nombreJourLocation;
  
  INSERT INTO Location (NumLocation, NumVehicule, Formule, DateDepart, DateRetour, NbKm, Montant) 
  VALUES (seqLocation.NEXTVAL, NumVeh, Formul, Depart, v_dateRetour, NULL, NULL);
  
  UPDATE Vehicule
  SET Situation = 'location'
  WHERE NumVehicule = NumVeh;

EXCEPTION
  WHEN vehicule_non_disponible THEN
    DBMS_OUTPUT.PUT_LINE('vehicule non disponible');
  WHEN vehicule_innexistant THEN
    DBMS_OUTPUT.PUT_LINE('vehicule innexistant');
  WHEN formule_innexistante THEN
    DBMS_OUTPUT.PUT_LINE('formule innexistante');
  WHEN parametre_manquant THEN
    DBMS_OUTPUT.PUT_LINE('parametre manquant');
  WHEN depart_incorrect THEN
    DBMS_OUTPUT.PUT_LINE('depart incorrect');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erreur Oracle dans LouerVehicule : '||sqlcode||' ; Message Oracle : '||sqlerrm);
END;
/
--Procédure VehiculesDisponibles NICOLAS
CREATE OR REPLACE PROCEDURE VehiculesDisponibles(Typ in varchar2)
IS
  v_nbType NUMBER;
  v_nbVehiculeCorrespondant NUMBER;
  v_listeVehiculesDisponibles VARCHAR2(4000);

  CURSOR c_Vehicules IS
    SELECT V.NumVehicule, M.Marque, M.Modele ,V.Matricule
    FROM Vehicule V, Modeles M, Types T
    WHERE V.Situation = 'disponible' 
      AND V.Modele = M.Modele 
      AND M.IdType = T.IdType 
      AND T.Type = Typ
    ORDER BY M.Marque, M.Modele;

  type_null EXCEPTION;
  type_inexistant EXCEPTION;
BEGIN
  IF Typ IS NULL THEN RAISE type_null ; END IF;

  SELECT COUNT(Type) INTO v_nbType FROM Types  WHERE Type = Typ;
  IF v_nbType = 0 THEN RAISE type_inexistant ; END IF;
  
  SELECT COUNT(*) INTO v_nbVehiculeCorrespondant 
  FROM Vehicule V, Modeles M, Types T  
  WHERE V.Situation = 'disponible' 
    AND V.Modele = M.Modele 
    AND M.IdType = T.IdType 
    AND T.Type = Typ;
    
  IF v_nbVehiculeCorrespondant = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Pas de vehicule disponible dans le type demande');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Vehicule(s) disponible(s) : ');
    FOR vehicule IN c_Vehicules LOOP
      DBMS_OUTPUT.PUT_LINE(vehicule.NumVehicule || ' / ' || vehicule.Modele || ' / ' || 
                           vehicule.Marque || ' / ' || vehicule.Matricule ||', ');
    END LOOP;
  END IF;
    
EXCEPTION
  WHEN type_null THEN
    DBMS_OUTPUT.PUT_LINE('type null');
  WHEN type_inexistant THEN
    DBMS_OUTPUT.PUT_LINE('type inexistant');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erreur Oracle dans VehiculesDisponibles : '||sqlcode||' ; Message Oracle : '||sqlerrm);
END;
/
--Procédure RetournerVehicule TOM
CREATE OR REPLACE PROCEDURE RetournerVehicule(NumVeh in number, Retour in date, Km in number)
IS
  v_nombreVehicule NUMBER;
  v_situationVehicule Vehicule.Situation%TYPE;
  v_dateDepart DATE;
  v_montant NUMBER;
  v_prixFormule NUMBER;
  v_prixKmSupp NUMBER;
  v_kmMax NUMBER;
  v_idTypeVehicule NUMBER;
  v_formuleVehiculeEnLocation Location.Formule%TYPE;
  vehicule_inexistant EXCEPTION;
  vehicule_non_loue EXCEPTION;
  date_retour_incorrecte EXCEPTION;
  km_negatif EXCEPTION;
  parametre_manquant EXCEPTION;
BEGIN
  IF NumVeh IS NULL OR Retour IS NULL OR Km IS NULL THEN RAISE parametre_manquant;END IF;
  
  SELECT Count(NumVehicule) INTO v_nombreVehicule FROM Vehicule WHERE NumVehicule = NumVeh;
  IF v_nombreVehicule = 0 THEN RAISE vehicule_inexistant; END IF;
  
  SELECT Situation INTO v_situationVehicule FROM Vehicule WHERE NumVehicule = NumVeh;
  IF v_situationVehicule != 'location' THEN RAISE vehicule_non_loue; END IF;
  
  SELECT DateDepart, Formule INTO v_dateDepart, v_formuleVehiculeEnLocation 
  FROM Location 
  WHERE NumVehicule = NumVeh 
    AND NbKm IS NULL;
  IF Retour < v_dateDepart THEN RAISE date_retour_incorrecte;END IF;
  
  IF Km < 0 THEN RAISE km_negatif;END IF;
  
  SELECT M.IdType INTO v_idTypeVehicule 
  FROM Modeles M, Vehicule V 
  WHERE M.Modele = V.Modele 
    AND NumVehicule = NumVeh;

  SELECT Prix, PrixKmSupp INTO v_prixFormule, v_prixKmSupp 
  FROM Tarif 
  WHERE IdType = v_idTypeVehicule 
    AND Formule = v_formuleVehiculeEnLocation;
  
  SELECT F.KmMax INTO v_kmMax 
  FROM Formules F, Location L 
  WHERE L.Formule = F.Formule 
    AND L.NumVehicule = NumVeh 
    AND NbKm IS NULL;
  
  v_montant := v_prixFormule + v_prixKmSupp * GREATEST(0,Km-v_kmMax);
  
  UPDATE Location
  SET NbKm = KM,
    Montant = v_montant,
    DateRetour = Retour
  WHERE NumVehicule = NumVeh AND NbKm IS NULL;
  
  UPDATE Vehicule 
  SET Situation = 'disponible'
  WHERE NumVehicule = NumVeh;

EXCEPTION
  WHEN parametre_manquant THEN
    DBMS_OUTPUT.PUT_LINE('parametre manquant');
  WHEN vehicule_inexistant THEN
    DBMS_OUTPUT.PUT_LINE('vehicule inexistant');
  WHEN vehicule_non_loue  THEN
    DBMS_OUTPUT.PUT_LINE('le vehicule ne peut pas etre loue');
  WHEN date_retour_incorrecte THEN
    DBMS_OUTPUT.PUT_LINE('date retour incorrecte');
  WHEN km_negatif THEN
    DBMS_OUTPUT.PUT_LINE('km negatif');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erreur Oracle dans RetournerVehicule : '||sqlcode||' ; Message Oracle : '||sqlerrm);
END;
/
--Fonction ChiffreAffaires HUGO
CREATE OR REPLACE FUNCTION ChiffreAffaires(Formul in varchar2, Typ in varchar2) return number
IS
  v_nombreFormule NUMBER;
  v_nombreType NUMBER;
  v_chiffreAffaire NUMBER := 0;
  formule_inexistante EXCEPTION;
  type_inexistant EXCEPTION;
BEGIN
  IF Formul IS NOT NULL THEN
    SELECT Count(*) INTO v_nombreFormule FROM Formules F WHERE Formul = F.Formule;
    IF v_nombreFormule = 0 THEN RAISE formule_inexistante; END IF;
  END IF;
  
  IF Typ IS NOT NULL THEN
    SELECT Count(*) INTO v_nombreType FROM Types T WHERE Typ = T.Type;
    IF v_nombreType = 0 THEN RAISE type_inexistant; END IF;
  END IF;
  
  IF Formul IS NOT NULL AND Typ IS NOT NULL THEN
    SELECT SUM(L.Montant) into v_chiffreAffaire 
    FROM Location L, Vehicule V, Modeles M, Types T 
    WHERE L.NumVehicule = V.NumVehicule 
      AND V.Modele = M.Modele 
      AND M.IdType = T.IdType 
      AND L.Formule = Formul 
      AND T.Type = Typ;
  END IF;
  
  IF Formul IS NULL AND Typ IS NOT NULL THEN
    SELECT SUM(L.Montant) into v_chiffreAffaire 
    FROM Location L, Vehicule V, Modeles M, Types T 
    WHERE L.NumVehicule = V.NumVehicule 
      AND V.Modele = M.Modele 
      AND M.IdType = T.IdType 
      AND T.Type = Typ;
  END IF;
  
  IF Formul IS NOT NULL AND Typ IS NULL THEN
    SELECT SUM(Montant) into v_chiffreAffaire 
    FROM Location
    WHERE Formule = Formul;
  END IF;
  
  IF Formul IS NULL AND Typ IS NULL THEN
    SELECT SUM(Montant) into v_chiffreAffaire 
    FROM Location;
  END IF;
  
  DBMS_OUTPUT.PUT_LINE('Resultat de CA - '||Formul||' - '||Typ||' = '||v_chiffreAffaire);
  RETURN v_chiffreAffaire;
  
EXCEPTION
  WHEN formule_inexistante THEN
    DBMS_OUTPUT.PUT_LINE('formule inexistante');
    RETURN NULL;
  WHEN type_inexistant THEN
    DBMS_OUTPUT.PUT_LINE('type inexistant');
    RETURN NULL;
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erreur Oracle dans ChiffreAffaires : '||sqlcode||' ; Message Oracle : '||sqlerrm);
    RETURN NULL;
END;
/
--Fonction FormuleAvantageuse NICOLAS
CREATE OR REPLACE FUNCTION FormuleAvantageuse(Duree in number, Typ in varchar2, Km in number)return varchar2
IS
  v_nombreType NUMBER;
  v_prixFormuleMin NUMBER;
  v_nomFormuleMin Formules.Formule%TYPE;
  v_FormuleAvantageuse VARCHAR2(4000);
  type_inexistant EXCEPTION;
  parametre_manquant EXCEPTION;
BEGIN
  IF Duree IS NULL OR Typ IS NULL OR Km IS NULL THEN RAISE parametre_manquant; END IF;
  
  SELECT Count(*) INTO v_nombreType FROM Types T WHERE Typ = T.Type;
  IF v_nombreType = 0 THEN RAISE type_inexistant; END IF;
  
  SELECT F.Formule, (Ta.Prix + GREATEST(Km - F.KmMax, 0) * Ta.PrixKmSupp) 
  INTO v_nomFormuleMin, v_prixFormuleMin
  FROM Formules F, Tarif Ta, Types Ty
  WHERE Ty.Type = Typ
    AND Ta.Formule = F.Formule
    AND Ty.IdType = Ta.IdType
    AND F.NbJours >= Duree
  ORDER BY (Ta.Prix + GREATEST(Km - F.KmMax, 0) * Ta.PrixKmSupp) ASC
  FETCH FIRST 1 ROW ONLY;
  
  v_FormuleAvantageuse := 'Formule Avantageuse: ' || v_nomFormuleMin || ' / Tarif Minimum: ' || v_prixFormuleMin;
  
  DBMS_OUTPUT.PUT_LINE(v_FormuleAvantageuse);
  RETURN v_FormuleAvantageuse;
  
EXCEPTION
  WHEN parametre_manquant THEN
    DBMS_OUTPUT.PUT_LINE('parametre manquant');
    RETURN NULL;
  WHEN type_inexistant THEN
    DBMS_OUTPUT.PUT_LINE('type inexistant');
    RETURN NULL;
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erreur Oracle dans FormuleAvantageuse : '||sqlcode||' ; Message Oracle : '||sqlerrm);
    RETURN NULL;
END;
/
-- INSERT des Types
INSERT INTO Types VALUES (1, 'Citadine');
INSERT INTO Types VALUES (2, 'Berline');
INSERT INTO Types VALUES (3, 'Monospace');
INSERT INTO Types VALUES (4, 'SUV');
INSERT INTO Types VALUES (5, '3m3');
INSERT INTO Types VALUES (6, '9m3');
INSERT INTO Types VALUES (7, '14m3');

-- INSERT des Modeles
INSERT INTO Modeles VALUES ('CLIO','Renault',1);
INSERT INTO Modeles VALUES ('SCENIC','Renault',3);
INSERT INTO Modeles VALUES ('208','Peugeot',1);
INSERT INTO Modeles VALUES ('508','Peugeot',2);
INSERT INTO Modeles VALUES ('PICASSO','Citroen',3);
INSERT INTO Modeles VALUES ('C3','Citroen',1);
INSERT INTO Modeles VALUES ('A4','Audi',2);
INSERT INTO Modeles VALUES ('TIGUAN','VW',4);
INSERT INTO Modeles VALUES ('5008','Peugeot',4);
INSERT INTO Modeles VALUES ('KANGOO','Renault',5);
INSERT INTO Modeles VALUES ('VITO','Mercedes',6);
INSERT INTO Modeles VALUES ('TRANSIT','Ford',6);
INSERT INTO Modeles VALUES ('DUCATO','Fiat',7);
INSERT INTO Modeles VALUES ('MASTER','Renault',7);

-- INSERT des Formules
INSERT INTO Formules VALUES ('jour',1,100);
INSERT INTO Formules VALUES ('fin-semaine',2,200);
INSERT INTO Formules VALUES ('semaine',7,500);
INSERT INTO Formules VALUES ('mois',30,1500);

-- INSERT des Tarifs
INSERT INTO Tarif VALUES (1,'jour',39,0.3);
INSERT INTO Tarif VALUES (1, 'fin-semaine', 69, 0.3);
INSERT INTO Tarif VALUES (1, 'semaine', 199, 0.3);
INSERT INTO Tarif VALUES (1, 'mois', 499, 0.3);
INSERT INTO Tarif VALUES (2, 'jour', 59, 0.4);
INSERT INTO Tarif VALUES (2, 'fin-semaine', 99, 0.4);
INSERT INTO Tarif VALUES (2, 'semaine', 299, 0.4);
INSERT INTO Tarif VALUES (2, 'mois', 799, 0.4);
INSERT INTO Tarif VALUES (3, 'jour', 69, 0.4);
INSERT INTO Tarif VALUES (3, 'fin-semaine', 129, 0.4);
INSERT INTO Tarif VALUES (3, 'semaine', 499, 0.4);
INSERT INTO Tarif VALUES (3, 'mois', 1099, 0.4);
INSERT INTO Tarif VALUES (4, 'jour', 69, 0.4);
INSERT INTO Tarif VALUES (4, 'fin-semaine', 129, 0.4);
INSERT INTO Tarif VALUES (4, 'semaine', 499, 0.4);
INSERT INTO Tarif VALUES (4, 'mois', 1099, 0.4);
INSERT INTO Tarif VALUES (5, 'jour', 39, 0.3);
INSERT INTO Tarif VALUES (5, 'fin-semaine', 79, 0.3);
INSERT INTO Tarif VALUES (5, 'semaine', 199, 0.3);
INSERT INTO Tarif VALUES (5, 'mois', 599, 0.3);
INSERT INTO Tarif VALUES (6, 'jour', 49, 0.4);
INSERT INTO Tarif VALUES (6, 'fin-semaine', 99, 0.4);
INSERT INTO Tarif VALUES (6, 'semaine', 259, 0.4);
INSERT INTO Tarif VALUES (6, 'mois', 899, 0.4);
INSERT INTO Tarif VALUES (7, 'jour', 79, 0.45);
INSERT INTO Tarif VALUES (7, 'fin-semaine', 159, 0.45);
INSERT INTO Tarif VALUES (7, 'semaine', 359, 0.45);
INSERT INTO Tarif VALUES (7, 'mois', 1199, 0.45);

COMMIT;
/
-- Test de AjouterVehicule
EXECUTE AjouterVehicule('CLIO','GA001AG','01/09/2021',1400);
EXECUTE AjouterVehicule('208','GA002AG','01/09/2021',1500);
EXECUTE AjouterVehicule('C3','GB003BG','15/09/2021',1000);
EXECUTE AjouterVehicule('A4','GB004BG','15/09/2021',500);
EXECUTE AjouterVehicule('508','GC006CG','01/10/2021',900);
EXECUTE AjouterVehicule('PICASSO','GF007FG','15/10/2021',300);
EXECUTE AjouterVehicule('SCENIC','GF008FG','15/10/2021',400);
EXECUTE AjouterVehicule('5008','GF009FG','15/10/2021',1000);
EXECUTE AjouterVehicule('KANGOO','GA010AG','01/09/2021',2000);
EXECUTE AjouterVehicule('TRANSIT','GA011AG','01/09/2021',2500);
-- La ligne suivante doit indiquer qu'on fait une modification d'un v hicule existant (Matricule en double)
EXECUTE AjouterVehicule('MASTER','GA011AG','11/09/2021',1500); 
-- La ligne suivante doit lever une erreur car le Kilom trage est n gatif
EXECUTE AjouterVehicule('DUCATO','GB013BG','15/09/2021',-1000);
--  La ligne suivante doit lever une erreur car le mod le est inexistant
EXECUTE AjouterVehicule('PASSAT','GC005CG','01/10/2021',1200);
-- La ligne suivante doit lever une erreur car une des valeurs est NULL (ou absente)
EXECUTE AjouterVehicule('208','GF005FG',NULL,1200);

-- Test de LouerVehicule
EXECUTE LouerVehicule(1,'jour',SYSDATE);
EXECUTE LouerVehicule(2,'mois',SYSDATE+1);
EXECUTE LouerVehicule(4,'jour',SYSDATE);
EXECUTE LouerVehicule(6,'fin-semaine',SYSDATE+2);
EXECUTE LouerVehicule(7,'semaine',SYSDATE);
EXECUTE LouerVehicule(10,'fin-semaine',SYSDATE+1);
-- La ligne suivante doit que le Véhicule est déjà en location (non disponible)
EXECUTE LouerVehicule(2,'semaine',SYSDATE+1);
-- La ligne suivante doit afficher que le Véhicule n'existe pas
EXECUTE LouerVehicule(11,'semaine',SYSDATE);
-- La ligne suivante doit afficher que le Formule n'existe pas 
EXECUTE LouerVehicule(3,'week-end',SYSDATE);

-- Test de VehiculesDisponibles
-- liste des véhicules de type 'Citadine' disponibles
EXECUTE VehiculesDisponibles('Citadine');
 -- La ligne suivante doit lever une erreur car il n'y a pas de v hicule disponible pour le type '14m3'
EXECUTE VehiculesDisponibles('14m3');
-- La ligne suivante doit afficher que le Type Utilitaire est inconnu
EXECUTE VehiculesDisponibles('Utilitaire');

-- Test de RetournerVehicule
EXECUTE RetournerVehicule(1,SYSDATE+3,120);
EXECUTE RetournerVehicule(4,SYSDATE+1,100);
EXECUTE RetournerVehicule(7,SYSDATE+7,900);
--  La ligne suivante doit afficher qu'il n'y a pas de location pour ce véhicule
EXECUTE RetournerVehicule(1,SYSDATE+1,100);
--  La ligne suivante doit afficher que le Véhicule n'existe pas
EXECUTE RetournerVehicule(11,SYSDATE+1,110); 
--  La ligne suivante doit afficher que la date de retour ne peut pas être inférieure à la date de départ
EXECUTE RetournerVehicule(6,SYSDATE+1,500);
--  La ligne suivante doit provoquer une erreur car Km est négatif ou nul
EXECUTE RetournerVehicule(6,SYSDATE+4,-500);

-- Test de ChiffreAffaires
-- Résultat de CA - Jour - Citadine = 45
SELECT ChiffreAffaires('jour','Citadine') FROM Dual; 
-- Résultat de CA - NULL - Monospace = 659
SELECT ChiffreAffaires(null,'Monospace') FROM Dual; 
-- Résultat de CA - Jour - NULL = 104
SELECT ChiffreAffaires('jour',null) FROM Dual;
-- Résultat de CA - NULL - NULL = 763
SELECT ChiffreAffaires(null,null) FROM Dual; 
-- Doit provoquer une erreur car la formule est inconnue (-1)
SELECT ChiffreAffaires('week-end','Berline') FROM Dual;
-- Doit provoquer une erreur car le type est inconnu (-2)
SELECT ChiffreAffaires('semaine', 'Utilitaire') FROM Dual;

-- Test de FormuleAvantageuse
-- La ligne suivante doit afficher que la formule "semaine" au Tarif de 199 Euros est la plus avantageuse
SELECT FormuleAvantageuse(3,'Citadine',500) FROM Dual;
-- ligne suivante doit afficher que le Type est inconnu
SELECT FormuleAvantageuse(3,'4x4',500) FROM Dual;
-- La ligne suivante doit afficher qu'un des paramètres ne peut pas être NULL
SELECT FormuleAvantageuse(3,'4x4',NULL) FROM Dual;
HXdYFvmZwLPwoc9ugz

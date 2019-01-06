### Dec 21, 2018
* Chenrui Qin shares a *nature* paper [Single-cell mapping of lineage and identity in direct reprogramming](https://www.nature.com/articles/s41586-018-0744-4) in the class;

---

### Dec 22, 2018
* Mettl7a1 is transiently and significantly **upregulated** along the successive reprogramming trajectory (Fig. 4b, c);
* Mettl7a1, an as-yet-uncharacterized **putative methyltransferase** in house mouse;
* Mettl3 catalyse mRNA m6A;
---
### Dec 23, 2018
* Three isoforms of _Mettl7a1_ @ house mouse
  * [Mus_Mettl7a1_X1_X2_X3](https://github.com/ZihuaLiu666/6mA/blob/master/Mus_Mettl7a1_X1_X2_X3.fasta)
  * [Human_Mettl7a_precursor](https://github.com/ZihuaLiu666/6mA/blob/master/Human_Mettl7a_precursor.fasta)
---
### Dec 24, 2018

* Question: 6mA content in different organelles
  * Separate mitochondria from nucleus, ask CC for help
---
### Jan 3, 2019
* DNA sequence
  * shRNA design and use [**antiSENSE.py**](https://github.com/ZihuaLiu666/6mA/blob/master/antiSENSE.py) script to call Forward and Reversed oligo sequence
    * @ [InvivoGene](https://www.invivogen.com/sirnawizard/design.php)
    * @ [HKU](https://i.cs.hku.hk/~sirna/software/sirna.php)
    * @ [ThermoFisher](https://www.thermofisher.com/cn/zh/home/life-science/rnai/synthetic-rnai-analysis/ambion-silencer-select-sirnas/silencer-select-sirna.html)
  * [Mettl7A](https://www.ncbi.nlm.nih.gov/nuccore/1519244361) of _Homo Sapiens_
    * 1 transcript
      * a: GAGAACCGACACCTGCAGTTT
      * b: GTGTTCGACTTGGAATTACTT
      * c: GTGATATACAACGAACAGATG
  * [Mettl4](https://www.ncbi.nlm.nih.gov/nuccore/1519241700) of _Homo Sapiens_
    * 2 transcript variants
      * a: GCAAATACCTATCCCTAAATT
      * b: CAAGGTGAATTGGATGCTATG
      * c: CTTTACCACTTGACGCCTGCA
    * 5 predicted transcript variants : [ORFfinder](https://www.ncbi.nlm.nih.gov/orffinder/)
      * [mtr4_Ptv1]()
      * [mtr4_Ptv2]()
      * [mtr4_Ptv3]()
      * [mtr4_Ptv4]()
      * [mtr4_Ptv5]()
    * misc RNA, RNA of unknown function
    
* Dr. Yi agrees to share the glioblastoma tumor cell with me
---
### Jan 4, 2019
* Cell passage
Introduction of [**Glioma brain tumors (astrocytoma, oligodendroglioma, glioblastoma)**](https://www.mayfieldclinic.com/PE-Glioma.htm)

    | Cell line | Medium | Disease     | Tissue | Biosafety |
    |:---------:|:------:|:-----------:|:------:|:---------:|
    | [H4](https://www.atcc.org/products/all/HTB-148.aspx#generalinformation)| DMEM   | neuroglioma | glial |1|
    | [GOS3](https://www.dsmz.de/de/kataloge/catalogue/culture/ACC-408.html)| MEM    | glioblastoma | glial |1|
    | [U251](https://www.kerafast.com/product/1790/u-251-mg-glioblastoma-cell-line)| MEM    | glioblastoma | glial |2|
* shRNA plasmid construct (see [protocol](https://github.com/ZihuaLiu666/6mA/blob/master/shRNA%20T4%20ligation%20protocol.pdf))
  * anneal
  * ligation
  * transformation
* pLKO.1 positive trans
  * WD will help with the MaxiPrep. work
---
### Jan 5, 2019
1. Digestion pLKO.1 
   * 4ug -> 128ng/uL @ 15uL 
2. shRNA constructs (with negative control, no oligo insertion)
3. Colony amplification
4. Cell passage
   * H4 (DPF)
     * 1+3+1.5
     * 1+3+1
   * GOS-3 (MPF)
     * 1+3+1.5
     * 1+3+1
5. Cell stock
   * 10% DMSO in DPF (Add 5mL DMSO to 45 mL DPF)
   * H4 80%
     * (1+3+1) -> 2 -> 1+1
   * GOS-3 90%
     * (1+3+1) -> 2 -> 1+1
---
### Jan 6, 2019
* Plasmid preparation(1-3: Mettl4; 6-8: Mettl7a)
  * 11
  * 21:22
  * 61:62
* Colony amplification
  * **results** 
    * <font color=#A0000E> Both exp. group and negative control group have colony, and I am not sure whether the pLKO.1 plasmid is cut or not.</font>
    * 1:2:3
    * 6:7:8
    * N (negative control dish)
* Cell passage
  * U251 70%
    * (1+3+1.5) * 2
* Cell stock
  * U251 70%
    * (1+3+1) -> 2 -> 1+1

---
## Ongoing work
- [x] Ask for glioblastoma 
- [x] HX would like to help me with the MS work
  * no detection on MEF
- [ ] WD will help with the MaxiPrep. work
- [x] Ask XPX about the virus package work, is there anything needed to be prepared in advance?
- [ ] Plasmid preparation and sequencing @ Jan 7
- [ ] <font color=#A0000E> Schedule the HEK293T cell, 7 dishes are need </font>
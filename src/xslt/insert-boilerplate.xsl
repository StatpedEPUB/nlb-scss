<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:dtbook="http://www.daisy.org/z3986/2005/dtbook/"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xmlns:nlb="http://www.nlb.no/ns/pipeline/xslt"
                exclude-result-prefixes="#all"
                version="2.0">
    
    <xsl:output indent="yes"/>
    
    <xsl:param name="braille-standard" select="'(dots:6)(grade:0)'"/>
    <xsl:param name="notes-placement" select="''"/>
    <xsl:param name="page-width" select="'38'"/>
    <xsl:param name="page-height" select="'29'"/>
    <xsl:param name="datetime" select="current-dateTime()"/>
    
    <xsl:variable name="contraction-grade" select="replace($braille-standard, '.*\(grade:(.*)\).*', '$1')"/>
    <xsl:variable name="line-width" select="xs:integer($page-width) - 6"/>
    
    <xsl:variable name="html-namespace" select="'http://www.w3.org/1999/xhtml'"/>
    <xsl:variable name="dtbook-namespace" select="'http://www.daisy.org/z3986/2005/dtbook/'"/>
    
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="html:html">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="* except html:body"/> <!-- also includes ol#generated-document-toc and ol#generated-volume-toc -->
            <xsl:choose>
                <!-- single body element => insert section after header -->
                <xsl:when test="count(html:body) = 1">
                    <xsl:for-each select="html:body">
                        <xsl:copy>
                            <xsl:apply-templates select="@*"/>
                            <xsl:apply-templates select="*[1][self::html:header]/(. | preceding-sibling::comment())"/>
                            <xsl:call-template name="generate-frontmatter"/>
                            <xsl:apply-templates select="node() except *[1][self::html:header]/(. | preceding-sibling::comment())"/>
                        </xsl:copy>
                    </xsl:for-each>
                </xsl:when>
                
                <!-- multiple body elements => create new body element -->
                <xsl:otherwise>
                    <xsl:apply-templates select="node() except html:body[1]/(. | following-sibling::node())"/>
                    <xsl:call-template name="generate-frontmatter"/>
                    <xsl:apply-templates select="html:body[1]/(. | following-sibling::node())"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="dtbook:book[not(dtbook:frontmatter)]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="frontmatter" namespace="{namespace-uri()}">
                <xsl:call-template name="generate-frontmatter"/>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="dtbook:frontmatter">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node() except dtbook:level1[1]/(. | following-sibling::node())"/>
            <xsl:call-template name="generate-frontmatter"/>
            <xsl:apply-templates select="dtbook:level1[1]/(. | following-sibling::node())"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template name="generate-frontmatter">
        <xsl:variable name="namespace-uri" select="namespace-uri()"/>
        
        <xsl:variable name="author" as="xs:string*">
            <xsl:choose>
                <xsl:when test="$namespace-uri = $dtbook-namespace">
                    <xsl:choose>
                        <xsl:when test="count(//dtbook:frontmatter/dtbook:docauthor)">
                            <xsl:sequence select="//dtbook:frontmatter/dtbook:docauthor/nlb:element-text(.)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="(//dtbook:head/dtbook:meta[@name = 'dc:Creator'])/string(@content)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="count(//html:body//html:*[tokenize(@epub:type,'\s+')='z3998:author'])">
                            <xsl:sequence select="//html:body//html:*[tokenize(@epub:type,'\s+')='z3998:author']/nlb:element-text(.)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="//html:head/html:meta[@name='dc:creator']/string(@content)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="fulltitle" as="xs:string">
            <xsl:choose>
                <xsl:when test="$namespace-uri = $dtbook-namespace">
                    <xsl:choose>
                        <xsl:when test="count(//dtbook:frontmatter/dtbook:doctitle)">
                            <xsl:sequence select="//dtbook:frontmatter/dtbook:doctitle/nlb:element-text(.)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="string((//dtbook:head/dtbook:meta[@name = 'dc:Title'])[1]/@content)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="count(//html:body//html:*[tokenize(@epub:type,'\s+')='fulltitle'])">
                            <xsl:sequence select="(//html:body//html:*[tokenize(@epub:type,'\s+')='fulltitle'])[1]/nlb:element-text(.)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="string((//html:head/html:title)[1]/text())"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="title" as="xs:string?">
            <xsl:choose>
                <xsl:when test="$namespace-uri = $dtbook-namespace">
                    <xsl:sequence select="(//dtbook:frontmatter/dtbook:doctitle//*[@class='title'])[1]/nlb:element-text(.)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="(//html:body//html:*[tokenize(@epub:type,'\s+')='title'])[1]/nlb:element-text(.)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="subtitle" as="xs:string?">
            <xsl:choose>
                <xsl:when test="$namespace-uri = $dtbook-namespace">
                    <xsl:sequence select="(//dtbook:frontmatter/dtbook:doctitle//*[@class='subtitle'])[1]/nlb:element-text(.)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="(//html:body//html:*[tokenize(@epub:type,'\s+')='subtitle'])[1]/nlb:element-text(.)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="translator" as="xs:string*">
            <xsl:choose>
                <xsl:when test="$namespace-uri = $dtbook-namespace">
                    <xsl:sequence select="//dtbook:head/dtbook:meta[@name = 'dc:Contributor.Translator']/string(@content)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="//html:head/html:meta[@name = 'dc:contributor.translator']/string(@content)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
  <xsl:variable name="pef-id" as="xs:string*">
            <xsl:choose>
                <xsl:when test="$namespace-uri = $dtbook-namespace">
                     <xsl:sequence select="//dtbook:head/dtbook:meta[@name = 'nlbprod:identifier.braille']/string(@content)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="//html:head/html:meta[@name = 'nlbprod:identifier.braille']/string(@content)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

         

        <xsl:variable name="language-id" as="xs:string*">
        <xsl:choose>
            <xsl:when test="$namespace-uri = $dtbook-namespace">
                <xsl:choose>
                    <xsl:when test="//dtbook:head/dtbook:meta[@name = 'dc:language']/string(@content)= 'nn'">
                         <xsl:sequence select="'NYNORSK'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="'BOKMÅL'"/>
                     </xsl:otherwise>
               </xsl:choose>
                 <!--  <xsl:sequence select="//dtbook:head/dtbook:meta[@name = 'dc:language']/string(@content)"/> -->
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:choose>
                     <xsl:when test="//html:head/html:meta[@name='dc:language']/string(@content)= 'nn'">
                        <xsl:sequence select="'NYNORSK'"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:sequence select="'BOKMÅL'"/>
                    </xsl:otherwise>
                 </xsl:choose>
                 <!--  <xsl:sequence select="//dtbook:head/dtbook:meta[@name = 'dc:language']/string(@content)"/> -->
                
                 <!--  <xsl:sequence select="//html:head/html:meta[@name='dc:language']/string(@content)"/> -->
                   
            </xsl:otherwise>
        </xsl:choose>
        </xsl:variable>

        <xsl:variable name="utgave-nummer" as="xs:string*">

            <xsl:choose>
                <xsl:when test="$namespace-uri = $dtbook-namespace">
                     <xsl:sequence select="//dtbook:head/dtbook:meta[@name = 'schema:bookEdition.original']/string(@content)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="//html:head/html:meta[@name = 'schema:bookEdition.original']/string(@content)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

          <xsl:variable name="forlag" as="xs:string*">
            <xsl:choose>
                <xsl:when test="$namespace-uri = $dtbook-namespace">
                     <xsl:sequence select="//dtbook:head/dtbook:meta[@name = 'dc:publisher.original']/string(@content)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="//html:head/html:meta[@name = 'dc:publisher.original']/string(@content)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

   <xsl:variable name="sted" as="xs:string*">
            <xsl:choose>
                <xsl:when test="$namespace-uri = $dtbook-namespace">
                     <xsl:sequence select="//dtbook:head/dtbook:meta[@name = 'dc:publisher.location.original']/string(@content)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="//html:head/html:meta[@name = 'dc:publisher.location.original']/string(@content)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

         <xsl:variable name="årstall" as="xs:string*">
            <xsl:choose>
                <xsl:when test="$namespace-uri = $dtbook-namespace">
                     <xsl:sequence select="//dtbook:head/dtbook:meta[@name = 'dc:date.issued.original']/string(@content)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="//html:head/html:meta[@name = 'dc:date.issued.original']/string(@content)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="forlag-sted-årstall" as="xs:string*">

              <xsl:sequence select="concat($forlag, ', ', $sted , ', ', $årstall)"/>       

        </xsl:variable>
         <xsl:variable name="utgave" as="xs:string*">
              <xsl:sequence select="concat('Utgave  ', $utgave-nummer)"/>          
        </xsl:variable>


        <xsl:variable name="original-publisher" as="xs:string?">
            <xsl:choose>
                <xsl:when test="$namespace-uri = $dtbook-namespace">
                    <xsl:sequence select="//dtbook:frontmatter/dtbook:level1[tokenize(@class,'\s+')='colophon']/dtbook:p[not(*) and starts-with(text(),'&#x00A9;')]/replace(text(),'^&#x00A9;\s+','')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="//html:body[(tokenize(@class,'\s+'),tokenize(@epub:type,'\s+'))='colophon']/html:p[not(*) and starts-with(text(),'&#x00A9;')]/replace(text(),'^&#x00A9;\s+','')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="original-isbn" as="xs:string?">
            <xsl:choose>
                <xsl:when test="$namespace-uri = $dtbook-namespace">
                    <xsl:sequence select="//dtbook:frontmatter/dtbook:level1[tokenize(@class,'\s+')='colophon']/dtbook:p[not(*) and matches(text(),'^(ISBN\s*)?[\d-]+$')]/replace(text(),'^(ISBN\s*)?([\d-]+)$','$1')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="//html:body[(tokenize(@class,'\s+'),tokenize(@epub:type,'\s+'))='colophon']/dtbook:p[not(*) and matches(text(),'^(ISBN\s*)?[\d-]+$')]/replace(text(),'^(ISBN\s*)?([\d-]+)$','$1')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

          <xsl:variable name="isbn" as="xs:string?">
           <xsl:choose>
                <xsl:when test="$namespace-uri = $dtbook-namespace">
                     <xsl:sequence select="//dtbook:head/dtbook:meta[@name = 'schema:isbn.original']/string(@content)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="//html:head/html:meta[@name = 'schema:isbn.original']/string(@content)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
         
        
        <xsl:variable name="grade-text" as="xs:string">
            <xsl:choose>
                <xsl:when test="$contraction-grade = '0'">
                    <xsl:text>Fullskrift</xsl:text>
                </xsl:when>
                <xsl:when test="$contraction-grade = '1'">
                    <xsl:text>Kortskrift 1</xsl:text>
                </xsl:when>
                <xsl:when test="$contraction-grade = '2'">
                    <xsl:text>Kortskrift 2</xsl:text>
                </xsl:when>
                <xsl:when test="$contraction-grade = '3'">
                    <xsl:text>Kortskrift 3</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text><![CDATA[]]></xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:element name="{nlb:level-element-name($namespace-uri, /*)}" namespace="{$namespace-uri}">
            <xsl:attribute name="class" select="'pef-titlepage'"/>
            
            <!-- 3 empty rows before author --> 
            <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
            <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
            <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
            <xsl:variable name="lines-used" select="3"/>
      
                  
        <xsl:variable name="author-multiple" select="substring-before($author,',')"/>
           <!--  if there is a semicolon delimeter there are more than one authors -->
                <xsl:if test="not($author-multiple)">  <!-- no delimiter found ; -->
                    <xsl:call-template name="row">
                    <xsl:with-param name="content" select="$author" />
                      <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
                        <xsl:with-param name="inline" select="true()"/>
                      </xsl:call-template>
               </xsl:if>

               <xsl:if test="$author-multiple">   
                    <xsl:call-template name="row">
                   
                    <xsl:with-param name="content" select="concat($author-multiple,' mfl.')"/>
                      <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
                        <xsl:with-param name="inline" select="true()"/>
                      </xsl:call-template>
               </xsl:if>
                  
 


          
                  

            <!-- 2 empty rows before title -->
          
                <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
                <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>

              <!-- TITLE ON LINE 6-->  

              <xsl:call-template name="SimpleStringLoop">
              <xsl:with-param name="input" select="$fulltitle"/>
              <xsl:with-param name="classes" select="'Innrykk-5'"/>
              <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
        
       </xsl:call-template>
     

        
       
            
              <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
                <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
                <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
                 <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
                <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
  <!-- LANGUAGE ON LINE 14-->  
               <xsl:call-template name="row">
                <xsl:with-param name="content" select="$language-id"/>
                   <xsl:with-param name="classes" select="'Innrykk-5'"/>
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
                <xsl:with-param name="inline" select="true()"/>
            </xsl:call-template>
                <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
  <!-- EDITION ON LINE 16-->         
              <xsl:call-template name="row">
                <xsl:with-param name="content" select="$utgave"/>
                   <xsl:with-param name="classes" select="'Innrykk-5'"/>
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
                <xsl:with-param name="inline" select="true()"/>
            </xsl:call-template>

                <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
                <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
                <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>

     <!-- PUBLISHER  ON LINE 20-->             
              <xsl:call-template name="row">
                <xsl:with-param name="content" select="$forlag-sted-årstall"/>
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
                <xsl:with-param name="inline" select="true()"/>
            </xsl:call-template>

         
              <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
              <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
  <!-- CCCCCC  ON LINE 23-->  
        <!--    <xsl:call-template name="row">
                <xsl:with-param name="content" select="'cccccccccccccccccccccccccccccc'"/> 
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
            </xsl:call-template>-->
cccccccccccccccccccccccccccccccc
            <xsl:call-template name="row">
                <xsl:with-param name="content" select="concat('statped, ',format-dateTime($datetime, '[Y]'))"/>
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
            </xsl:call-template>
            
    
            <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
            <xsl:call-template name="empty-row"><xsl:with-param name="namespace-uri" select="$namespace-uri"/></xsl:call-template>
       <!-- VOLUME NO  ON LINE 27-->        
            <xsl:call-template name="row">
                <xsl:with-param name="content" select="' av '"/>
                <xsl:with-param name="classes" select="'pef-volume'"/>
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
                <xsl:with-param name="inline" select="true()"/>
            </xsl:call-template>
 <!-- PROD NO  ON LINE 28--> 
              <xsl:call-template name="row">
                <xsl:with-param name="content" select="$pef-id"/>
                 <xsl:with-param name="classes" select="'Høyre-justert'"/>
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
              
            </xsl:call-template>
        </xsl:element>
        
        <!-- end of titlepage, beginning of about page -->

        <xsl:variable name="notes-present" as="xs:boolean"
                      select="exists(//dtbook:note|//@epub:type[tokenize(.,'\s+') = ('note','footnote','endnote','rearnote')])"/>
        <xsl:variable name="notes-placement-text">
            <xsl:choose>
                <xsl:when test="$notes-placement = 'bottom-of-page'">
                    <xsl:text>Noter er plassert nederst på hver side.</xsl:text>
                </xsl:when>
                <xsl:when test="$notes-placement = 'end-of-volume'">
                    <xsl:text>Noter er plassert i slutten av hvert hefte.</xsl:text>
                </xsl:when>
                <xsl:when test="$notes-placement = 'end-of-book'">
                    <xsl:text>Noter er plassert bakerst i boken.</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="final-rows" as="element()*">
       <!--   <xsl:call-template name="row">
                <xsl:with-param name="content" select="'Denne boka er skrevet av:'"/>
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
                <xsl:with-param name="inline" select="true()"/>
            </xsl:call-template>

   
       <xsl:call-template name="SimpleStringLoop">
              <xsl:with-param name="input" select="$author"/>
              <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
        
       </xsl:call-template>-->
     
         

           <xsl:call-template name="row">
                <xsl:with-param name="content" select="'Punktsidetallet er midtstilt nederst på siden. Full celle i margen og foran sidetallet nederst
                til høyre markerer sideskift i originalboka. '"/>
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
                <xsl:with-param name="inline" select="true()"/>
            </xsl:call-template>

            <xsl:call-template name="row">
                <xsl:with-param name="content" select="'Tekst og bilder kan være flyttet til en annen side for å unngå
                å bryte opp løpende tekst. Ordforklaringer og stikkord finner du som regel etter teksten de tilhører, 
               etter eventuelle bilder. '"/>
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
                <xsl:with-param name="inline" select="true()"/>
            </xsl:call-template>
            
             <xsl:call-template name="row">
                <xsl:with-param name="content" select="'Bildebeskrivelser står mellom punktene (56-3) og (6-23): &lt;.Bildebeskrivelse’;'"/>
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
                <xsl:with-param name="inline" select="true()"/>
            </xsl:call-template>

           <xsl:call-template name="row">
                <xsl:with-param name="content" select="'Til uthevinger generelt brukes punktene (23) og (56): ;Utheving&lt;'"/>
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
                <xsl:with-param name="inline" select="true()"/>
            </xsl:call-template>
                
            <xsl:call-template name="row">
                <xsl:with-param name="content" select="'Boka skal ikke returneres.'"/>
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
            </xsl:call-template>
           
        </xsl:variable>
        <xsl:element name="{nlb:level-element-name($namespace-uri, /*)}" namespace="{$namespace-uri}">
            <xsl:attribute name="class" select="'pef-about'"/>
            <xsl:element name="h1" namespace="{$namespace-uri}">
                <xsl:text>Merknad til punktskriftutgaven</xsl:text>
            </xsl:element>
           
        
            <xsl:if test="not($notes-present and $notes-placement = 'bottom-of-page')">
                <xsl:if test="$notes-present">
                    <xsl:call-template name="row">
                        <xsl:with-param name="content" select="$notes-placement-text"/>
                        <xsl:with-param name="classes" select="'notes-placement'"/>
                        <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
                    </xsl:call-template>
                </xsl:if>
                <xsl:sequence select="$final-rows"/>
            </xsl:if>
        </xsl:element>
        <!--
            in order for -obfl-use-when-collection-not-empty to work the "notes-placement" and
            "notes-placement-fallback" elements must be added to a named flow directly (not via
            their parent element)
        -->
        <xsl:if test="$notes-present and $notes-placement = 'bottom-of-page'">
            <xsl:call-template name="row">
                <xsl:with-param name="content" select="$notes-placement-text"/>
                <xsl:with-param name="classes" select="('pef-about','notes-placement')"/>
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
            </xsl:call-template>
            <xsl:call-template name="row">
                <xsl:with-param name="content">Noter er plassert i slutten av hvert hefte.</xsl:with-param>
                <xsl:with-param name="classes" select="('pef-about','notes-placement-fallback')"/>
                <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
            </xsl:call-template>
            <xsl:element name="div" namespace="{$namespace-uri}">
                <xsl:attribute name="class" select="'pef-about'"/>
                <xsl:sequence select="$final-rows"/>
            </xsl:element>
        </xsl:if>
    </xsl:template>

      

    
    <xsl:template name="empty-row" as="element()">
        <xsl:param name="namespace-uri" as="xs:string"/>
        <xsl:call-template name="row">
            <xsl:with-param name="content" select="'&#160;'"/>
            <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="row" as="element()">
        <xsl:param name="content" as="xs:string"/>
        <xsl:param name="classes" as="xs:string*"/>
        <xsl:param name="namespace-uri" as="xs:string"/>
        <xsl:param name="inline" select="false()"/>
        <xsl:choose>
            <xsl:when test="$inline">
                <xsl:element name="p" namespace="{$namespace-uri}">
                    <xsl:element name="span" namespace="{$namespace-uri}">
                        <xsl:if test="exists($classes)">
                            <xsl:attribute name="class" select="$classes"/>
                        </xsl:if>
                        <xsl:value-of select="$content"/>
                    </xsl:element>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="p" namespace="{$namespace-uri}">
                    <xsl:if test="exists($classes)">
                      <!--  <xsl:attribute name="class" select="string-join($classes,' ')"/> -->
                      <xsl:attribute name="class" select="$classes"/>
                    </xsl:if>
                    <xsl:value-of select="$content"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


     <xsl:template name="SimpleStringLoop">
        <xsl:param name="input" as="xs:string"/>
         <xsl:param name="classes" as="xs:string*"/>
         <xsl:param name="namespace-uri"/>
        <xsl:variable name="nb_char" select="string-length($input)-string-length(translate($input,';',''))"/>
      
       <xsl:choose>
       <xsl:when test="$nb_char !=0">  <!-- delimiter found-->
         
        <xsl:if test="string-length($input) &gt; 0">
            <xsl:variable name="v2" select="substring-before($input, ',')"/>
             <xsl:variable name="class2" select="$classes"/>
            <xsl:call-template name="row">
                    <xsl:with-param name="content" select="$v2" />
                     <xsl:with-param name="classes" select="$class2"/>
                      <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
                        <xsl:with-param name="inline" select="true()"/>
                      </xsl:call-template>
            <xsl:call-template name="SimpleStringLoop">
                <xsl:with-param name="input" select="substring-after($input, ',')"/> 
                <xsl:with-param name="classes" select="$class2"/>  
                  <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
            </xsl:call-template>
               
        </xsl:if> 
      </xsl:when> 
      <xsl:otherwise>
        <xsl:call-template name="row">
                    <xsl:with-param name="content" select="$input" />
                     <xsl:with-param name="classes" select="'Innrykk-5'"/>
                      <xsl:with-param name="namespace-uri" select="$namespace-uri"/>
                        <xsl:with-param name="inline" select="true()"/>
                      </xsl:call-template>
      </xsl:otherwise>
</xsl:choose>
   
    </xsl:template>
   

    <xsl:function name="nlb:level-element-name" as="xs:string">
        <xsl:param name="namespace-uri" as="xs:string"/>
        <xsl:param name="document" as="element()"/>
        <xsl:choose>
            <xsl:when test="$namespace-uri = $dtbook-namespace">
                <xsl:sequence select="'level1'"/>
            </xsl:when>
            <xsl:when test="count($document/html:body) = 1">
                <xsl:sequence select="'section'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="'body'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
  <xsl:function name="nlb:element-text" as="xs:string?">
        <xsl:param name="element" as="element()"/>
        
        <xsl:variable name="result" as="xs:string*">
            <xsl:for-each select="$element/node()">
                <xsl:if test="(tokenize(@class,'\s+'), tokenize(@epub:type,'\s+')) = ('title', 'subtitle')">
                    <xsl:sequence select="'&#10;'"/>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="self::text()">
                        <xsl:sequence select="replace(.,'\s+',' ')"/>
                    </xsl:when>
                    <xsl:when test="(self::html:br | self::dtbook:br)[tokenize(@class,'\s+') = 'display-braille']">
                        <xsl:sequence select="'&#10;'"/>
                    </xsl:when>
                    <xsl:when test="self::*">
                        <xsl:sequence select="nlb:element-text(.)"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="if (count($result)) then replace(replace(replace(replace(string-join($result,''),'&#10; ',' &#10;'),' +',' '),'(^ | $)',''),'^&#10;+','') else ()"/>
    </xsl:function>
    
   
    
</xsl:stylesheet>
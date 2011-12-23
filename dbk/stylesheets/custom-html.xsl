<?xml version="1.0"?>
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0">
<xsl:output method="html"/>

<xsl:template match="acronym">
<acronym>
<xsl:attribute name="title">
<xsl:value-of select="@role"/>
</xsl:attribute>
<xsl:value-of select="."/>
</acronym>
</xsl:template>

<xsl:template match="citetitle">
<cite><xsl:value-of select="."/></cite>
</xsl:template>

<xsl:template match="emphasis">
<em><xsl:value-of select="."/></em>
</xsl:template>

<xsl:template match="quote">
<q><xsl:value-of select="."/></q>
</xsl:template>

<!--
How do I add character entities to the output from an XSL stylesheet 
(such as &copy; below)?
<xsl:template match="trademark">
<xsl:value-of select="."/>
<xsl:choose>
<xsl:when text="@class">
<xsl:text>&copy;</xsl:text>
</xsl:when>
<xsl:otherwise>
<xsl:text>&reg;</xsl:text>
</xsl:otherwise>
</xsl:choose>
</xsl:template>
-->

</xsl:stylesheet>

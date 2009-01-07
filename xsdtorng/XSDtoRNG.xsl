<?xml version="1.0" encoding="UTF-8"?>
<!--
Copyright or © or Copr. Nicolas Debeissat

debeissat.nicolas@gmail.com

This software is a computer program whose purpose is to convert a
XSD schema into a RelaxNG schema.

This software is governed by the CeCILL license under French law and
abiding by the rules of distribution of free software.  You can  use, 
modify and/ or redistribute the software under the terms of the CeCILL
license as circulated by CEA, CNRS and INRIA at the following URL
"http://www.cecill.info". 

As a counterpart to the access to the source code and  rights to copy,
modify and redistribute granted by the license, users are provided only
with a limited warranty  and the software's author,  the holder of the
economic rights,  and the successive licensors  have only  limited
liability. 

In this respect, the user's attention is drawn to the risks associated
with loading,  using,  modifying and/or developing or reproducing the
software by the user in light of its specific status of free software,
that may mean  that it is complicated to manipulate,  and  that  also
therefore means  that it is reserved for developers  and  experienced
professionals having in-depth computer knowledge. Users are therefore
encouraged to load and test the software's suitability as regards their
requirements in conditions enabling the security of their systems and/or 
data to be ensured and,  more generally, to use and operate it in the 
same conditions as regards security. 

The fact that you are presently reading this means that you have had
knowledge of the CeCILL license and that you accept its terms.

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0" exclude-result-prefixes="xs" version="1.0">
	<xsl:output indent="yes" method="xml"/>
	<xsl:preserve-space elements="*"/>
	<xsl:template match="/xs:schema">
		<?xml-stylesheet type="text/xsl" href="RNGtoHTMLform_standalone.xsl"?>
		<rng:grammar>
			<xsl:for-each select="namespace::*">
				<xsl:if test="local-name() != 'xs'">
					<xsl:copy/>
				</xsl:if>
			</xsl:for-each>
			<xsl:attribute name="ns"><xsl:value-of select="@targetNamespace"/></xsl:attribute>
			<xsl:attribute name="datatypeLibrary">http://www.w3.org/2001/XMLSchema-datatypes</xsl:attribute>
			<xsl:apply-templates/>
		</rng:grammar>
	</xsl:template>
	<xsl:template match="comment()">
		<xsl:copy/>
	</xsl:template>
	<xsl:template match="xs:annotation">
		<a:documentation>
			<xsl:apply-templates/>
		</a:documentation>
	</xsl:template>
	<xsl:template match="xs:documentation">
		<xsl:copy-of select="child::text()"/>
	</xsl:template>
	<xsl:template match="xs:appinfo">
		<xsl:copy-of select="child::node()"/>
	</xsl:template>
	<xsl:template match="xs:complexType[@name]|xs:simpleType[@name]|xs:group[@name]">
		<!-- the schemas may be included several times, so it needs a combine attribute
                                     (the attributes are inversed :-) at the transformation) -->
		<rng:define name="{@name}">
			<xsl:apply-templates/>
		</rng:define>
	</xsl:template>
	<xsl:template match="xs:group[@ref]">
		<xsl:call-template name="occurencies"/>
	</xsl:template>
	<xsl:template match="xs:group[@ref]" mode="content">
		<xsl:call-template name="type">
			<xsl:with-param name="type" select="@ref"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="xs:attribute[@name]">
		<xsl:call-template name="occurencies"/>
	</xsl:template>
	<xsl:template match="xs:attribute[@name]" mode="content">
		<rng:attribute name="{@name}">
			<!-- there can be no type attribute to <xs:attribute>, in this case, the type is defined in 
                                    a <xs:simpleType> or a <xs:complexType> inside -->
			<xsl:choose>
				<xsl:when test="@type">
					<xsl:call-template name="type">
						<xsl:with-param name="type" select="@type"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
		</rng:attribute>
	</xsl:template>
	<!-- the <xs:simpleType> and <xs:complexType without type attribute are ignored -->
	<xsl:template match="xs:sequence|xs:complexContent|xs:simpleType|xs:complexType">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="xs:extension[@base]">
		<xsl:call-template name="type">
			<xsl:with-param name="type" select="@base"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="xs:any ">
		<xsl:call-template name="occurencies"/>
	</xsl:template>
	<xsl:template match="xs:any " mode="content">
		<rng:element>
			<rng:anyName/>
			<rng:text/>
		</rng:element>
	</xsl:template>
	<xsl:template match="xs:choice">
		<rng:choice>
			<xsl:apply-templates/>
		</rng:choice>
	</xsl:template>
	<xsl:template match="xs:element[@name]">
		<!-- case of root element -->
		<xsl:choose>
			<xsl:when test="parent::xs:schema">
				<rng:start>
					<rng:ref name="{@name}"/>
				</rng:start>
				<rng:define name="{@name}">
					<xsl:apply-templates select="current()" mode="content"/>
				</rng:define>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="occurencies"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xs:element" mode="content">
		<rng:element name="{@name}">
			<xsl:choose>
				<xsl:when test="@type">
					<xsl:call-template name="type">
						<xsl:with-param name="type" select="@type"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
		</rng:element>
	</xsl:template>
	<xsl:template match="xs:restriction[@base]">
		<xsl:choose>
			<xsl:when test="xs:enumeration[@value]">
				<rng:choice>
					<xsl:apply-templates/>
				</rng:choice>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="type">
					<xsl:with-param name="type" select="@base"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xs:enumeration[@value]">
		<rng:value>
			<xsl:value-of select="@value"/>
		</rng:value>
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="xs:minInclusive[@value]|xs:minExclusive[@value]|xs:maxInclusive[@value]|xs:maxExclusive[@value]|xs:pattern[@value]">
		<rng:param name="{name()}">
			<xsl:value-of select="@value"/>
		</rng:param>
	</xsl:template>
	<xsl:template match="xs:all">
		<rng:interleave>
			<xsl:for-each select="child::text()[normalize-space(.)] | child::*">
				<rng:optional>
					<xsl:apply-templates select="current()"/>
				</rng:optional>
			</xsl:for-each>
		</rng:interleave>
	</xsl:template>
	<xsl:template match="xs:import[@schemaLocation][@namespace]">
		<xsl:variable name="schemaLocation" select="substring-before(@schemaLocation,'.xsd')"/>
		<rng:include href="{$schemaLocation}.rng" ns="{@namespace}"/>
	</xsl:template>
	<xsl:template name="occurencies">
		<xsl:choose>
			<xsl:when test="@use and @use='optional'">
				<rng:optional>
					<xsl:call-template name="default"/>
					<xsl:apply-templates select="current()" mode="content"/>
				</rng:optional>
			</xsl:when>
			<xsl:when test="@maxOccurs and @maxOccurs='unbounded'">
				<xsl:choose>
					<xsl:when test="@minOccurs and @minOccurs='0'">
						<rng:zeroOrMore>
							<xsl:call-template name="default"/>
							<xsl:apply-templates select="current()" mode="content"/>
						</rng:zeroOrMore>
					</xsl:when>
					<xsl:otherwise>
						<rng:oneOrMore>
							<xsl:call-template name="default"/>
							<xsl:apply-templates select="current()" mode="content"/>
						</rng:oneOrMore>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="@minOccurs and @minOccurs='0'">
				<rng:optional>
					<xsl:call-template name="default"/>
					<xsl:apply-templates select="current()" mode="content"/>
				</rng:optional>
			</xsl:when>
			<!-- here minOccurs is present but not = 0 -->
			<xsl:when test="@minOccurs">
				<xsl:call-template name="loopUntilZero">
					<xsl:with-param name="nbLoops" select="@minOccurs"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="default"/>
				<xsl:apply-templates select="current()" mode="content"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="default">
		<xsl:if test="@default">
			<a:documentation>
                default value is : <xsl:value-of select="@default"/>
			</a:documentation>
		</xsl:if>
	</xsl:template>
	<xsl:template name="loopUntilZero">
		<xsl:param name="nbLoops"/>
		<xsl:if test="$nbLoops > 0">
			<xsl:call-template name="default"/>
			<xsl:apply-templates select="current()" mode="content"/>
			<xsl:call-template name="loopUntilZero">
				<xsl:with-param name="nbLoops" select="$nbLoops - 1"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<xsl:template name="type">
		<xsl:param name="type"/>
		<xsl:choose>
			<xsl:when test="contains($type,'anyType')">
				<rng:data type="string">
					<xsl:apply-templates/>
				</rng:data>
			</xsl:when>
			<xsl:when test="starts-with($type,'xs:')">
				<rng:data type="{substring-after($type,':')}">
					<xsl:apply-templates/>
				</rng:data>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="contains($type,':')">
						<rng:ref name="{substring-after($type,':')}"/>
						<xsl:apply-templates/>
					</xsl:when>
					<xsl:otherwise>
						<rng:ref name="{$type}"/>
						<xsl:apply-templates/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- <xsl:when test="/xs:schema/xs:complexType[@name=$type]|/xs:schema/xs:simpleType[@name=$type]"> -->
</xsl:stylesheet>

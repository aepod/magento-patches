#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


PATCH_SUPEE-9767_CE_1.6.2.0_v2 | CE_1.6.2.0 | v2 | 6566db274beaeb9bcdb56a62e02cc2da532e618c | Thu Jun 22 04:30:03 2017 +0300 | v1.14.3.3..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Admin/Model/Session.php app/code/core/Mage/Admin/Model/Session.php
index 625d610..c2244ea 100644
--- app/code/core/Mage/Admin/Model/Session.php
+++ app/code/core/Mage/Admin/Model/Session.php
@@ -139,6 +139,9 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
             }
         }
         catch (Mage_Core_Exception $e) {
+            $e->setMessage(
+                Mage::helper('adminhtml')->__('You did not sign in correctly or your account is temporarily disabled.')
+            );
             Mage::dispatchEvent('admin_session_user_login_failed',
                     array('user_name' => $username, 'exception' => $e));
             if ($request && !$request->getParam('messageSent')) {
diff --git app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php
new file mode 100644
index 0000000..3106d62
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php
@@ -0,0 +1,52 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Mage_Adminhtml_Block_Checkout_Formkey
+ */
+class Mage_Adminhtml_Block_Checkout_Formkey extends Mage_Adminhtml_Block_Template
+{
+    /**
+     * Check form key validation on checkout.
+     * If disabled, show notice.
+     *
+     * @return boolean
+     */
+    public function canShow()
+    {
+        return !Mage::getStoreConfigFlag('admin/security/validate_formkey_checkout');
+    }
+
+    /**
+     * Get url for edit Advanced -> Admin section
+     *
+     * @return string
+     */
+    public function getSecurityAdminUrl()
+    {
+        return Mage::helper("adminhtml")->getUrl('adminhtml/system_config/edit/section/admin');
+    }
+}
diff --git app/code/core/Mage/Adminhtml/Block/Notification/Symlink.php app/code/core/Mage/Adminhtml/Block/Notification/Symlink.php
new file mode 100644
index 0000000..ac33fa4
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Notification/Symlink.php
@@ -0,0 +1,36 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+class Mage_Adminhtml_Block_Notification_Symlink extends Mage_Adminhtml_Block_Template
+{
+    /**
+     * @return bool
+     */
+    public function isSymlinkEnabled()
+    {
+        return Mage::getStoreConfigFlag(self::XML_PATH_TEMPLATE_ALLOW_SYMLINK);
+    }
+}
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
index 6d11247..478739a 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
@@ -137,11 +137,11 @@ class Mage_Adminhtml_Block_Widget_Grid_Column_Filter_Date extends Mage_Adminhtml
         if (isset($value['locale'])) {
             if (!empty($value['from'])) {
                 $value['orig_from'] = $value['from'];
-                $value['from'] = $this->_convertDate($value['from'], $value['locale']);
+                $value['from'] = $this->_convertDate($this->stripTags($value['from']), $value['locale']);
             }
             if (!empty($value['to'])) {
                 $value['orig_to'] = $value['to'];
-                $value['to'] = $this->_convertDate($value['to'], $value['locale']);
+                $value['to'] = $this->_convertDate($this->stripTags($value['to']), $value['locale']);
             }
         }
         if (empty($value['from']) && empty($value['to'])) {
diff --git app/code/core/Mage/Adminhtml/Model/Config/Data.php app/code/core/Mage/Adminhtml/Model/Config/Data.php
index d28d0f7..ce4d3fa 100644
--- app/code/core/Mage/Adminhtml/Model/Config/Data.php
+++ app/code/core/Mage/Adminhtml/Model/Config/Data.php
@@ -153,6 +153,9 @@ class Mage_Adminhtml_Model_Config_Data extends Varien_Object
                 if (is_object($fieldConfig)) {
                     $configPath = (string)$fieldConfig->config_path;
                     if (!empty($configPath) && strrpos($configPath, '/') > 0) {
+                        if (!Mage::getSingleton('admin/session')->isAllowed($configPath)) {
+                            Mage::throwException('Access denied.');
+                        }
                         // Extend old data with specified section group
                         $groupPath = substr($configPath, 0, strrpos($configPath, '/'));
                         if (!isset($oldConfigAdditionalGroups[$groupPath])) {
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Symlink.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Symlink.php
new file mode 100644
index 0000000..9519a66
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Symlink.php
@@ -0,0 +1,44 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * System config symlink backend model
+ *
+ * @category Mage
+ * @package  Mage_Adminhtml
+ */
+class Mage_Adminhtml_Model_System_Config_Backend_Symlink extends Mage_Core_Model_Config_Data
+{
+    /**
+     * Save object data
+     *
+     * @return Mage_Core_Model_Abstract
+     */
+    public function save()
+    {
+        return $this;
+    }
+}
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php
index 75e8838..3ce851e 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php
@@ -42,6 +42,11 @@ class Mage_Adminhtml_Catalog_Product_GalleryController extends Mage_Adminhtml_Co
                 Mage::helper('catalog/image'), 'validateUploadFile');
             $uploader->setAllowRenameFiles(true);
             $uploader->setFilesDispersion(true);
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                Mage::getModel('core/file_validator_image'),
+                'validate'
+            );
             $result = $uploader->save(
                 Mage::getSingleton('catalog/product_media_config')->getBaseTmpMediaPath()
             );
diff --git app/code/core/Mage/Checkout/controllers/MultishippingController.php app/code/core/Mage/Checkout/controllers/MultishippingController.php
index 101229d..176eade 100644
--- app/code/core/Mage/Checkout/controllers/MultishippingController.php
+++ app/code/core/Mage/Checkout/controllers/MultishippingController.php
@@ -233,6 +233,12 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
             $this->_redirect('*/multishipping_address/newShipping');
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            $this->_redirect('*/*/addresses');
+            return;
+        }
+
         try {
             if ($this->getRequest()->getParam('continue', false)) {
                 $this->_getCheckout()->setCollectRatesFlag(true);
@@ -339,6 +345,11 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
 
     public function shippingPostAction()
     {
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            $this->_redirect('*/*/shipping');
+            return;
+        }
+
         $shippingMethods = $this->getRequest()->getPost('shipping_method');
         try {
             Mage::dispatchEvent(
@@ -442,6 +453,11 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
             return $this;
         }
 
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            $this->_redirect('*/*/billing');
+            return;
+        }
+
         $this->_getState()->setActiveStep(Mage_Checkout_Model_Type_Multishipping_State::STEP_OVERVIEW);
 
         try {
diff --git app/code/core/Mage/Checkout/controllers/OnepageController.php app/code/core/Mage/Checkout/controllers/OnepageController.php
index 7c0dda9..9fc8ee2 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -310,6 +310,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
         if ($this->getRequest()->isPost()) {
             $method = $this->getRequest()->getPost('method');
             $result = $this->getOnepage()->saveCheckoutMethod($method);
@@ -325,6 +326,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
 //            $postData = $this->getRequest()->getPost('billing', array());
 //            $data = $this->_filterPostData($postData);
@@ -370,6 +376,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
             $data = $this->getRequest()->getPost('shipping', array());
             $customerAddressId = $this->getRequest()->getPost('shipping_address_id', false);
@@ -394,6 +405,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
             $data = $this->getRequest()->getPost('shipping_method', '');
             $result = $this->getOnepage()->saveShippingMethod($data);
@@ -428,6 +444,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         try {
             if (!$this->getRequest()->isPost()) {
                 $this->_ajaxRedirectResponse();
diff --git app/code/core/Mage/Checkout/etc/system.xml app/code/core/Mage/Checkout/etc/system.xml
index 499ddd0..4cb85c1 100644
--- app/code/core/Mage/Checkout/etc/system.xml
+++ app/code/core/Mage/Checkout/etc/system.xml
@@ -222,5 +222,23 @@
                 </payment_failed>
             </groups>
         </checkout>
+        <admin>
+            <groups>
+                <security>
+                    <fields>
+                        <validate_formkey_checkout translate="label comment">
+                            <label>Enable Form Key Validation On Checkout</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>4</sort_order>
+                            <comment><![CDATA[<strong style="color:red">Important!</strong> Enabling this option means
+                            that your custom templates used in checkout process contain form_key output.
+                            Otherwise checkout may not work.]]></comment>
+                            <show_in_default>1</show_in_default>
+                        </validate_formkey_checkout>
+                    </fields>
+                </security>
+            </groups>
+        </admin>
     </sections>
 </config>
diff --git app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
index 8d7192f..a0a7fed 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
@@ -282,6 +282,11 @@ class Mage_Cms_Model_Wysiwyg_Images_Storage extends Varien_Object
         }
         $uploader->setAllowRenameFiles(true);
         $uploader->setFilesDispersion(false);
+        $uploader->addValidateCallback(
+            Mage_Core_Model_File_Validator_Image::NAME,
+            Mage::getModel('core/file_validator_image'),
+            'validate'
+        );
         $result = $uploader->save($targetPath);
 
         if (!$result) {
diff --git app/code/core/Mage/Core/Controller/Front/Action.php app/code/core/Mage/Core/Controller/Front/Action.php
index 50dcdfe..f52505d 100644
--- app/code/core/Mage/Core/Controller/Front/Action.php
+++ app/code/core/Mage/Core/Controller/Front/Action.php
@@ -34,6 +34,11 @@
 class Mage_Core_Controller_Front_Action extends Mage_Core_Controller_Varien_Action
 {
     /**
+     * Add secret key to url config path
+     */
+    const XML_CSRF_USE_FLAG_CONFIG_PATH   = 'system/csrf/use_form_key';
+
+    /**
      * Currently used area
      *
      * @var string
@@ -152,4 +157,38 @@ class Mage_Core_Controller_Front_Action extends Mage_Core_Controller_Varien_Acti
         }
         return $this;
     }
+
+    /**
+     * Validate Form Key
+     *
+     * @return bool
+     */
+    protected function _validateFormKey()
+    {
+        $validated = true;
+        if ($this->_isFormKeyEnabled()) {
+            $validated = parent::_validateFormKey();
+        }
+        return $validated;
+    }
+
+    /**
+     * Check if form key validation is enabled.
+     *
+     * @return bool
+     */
+    protected function _isFormKeyEnabled()
+    {
+        return Mage::getStoreConfigFlag(self::XML_CSRF_USE_FLAG_CONFIG_PATH);
+    }
+
+    /**
+     * Check if form_key validation enabled on checkout process
+     *
+     * @return bool
+     */
+    protected function isFormkeyValidationOnCheckoutEnabled()
+    {
+        return Mage::getStoreConfigFlag('admin/security/validate_formkey_checkout');
+    }
 }
diff --git app/code/core/Mage/Core/Controller/Request/Http.php app/code/core/Mage/Core/Controller/Request/Http.php
index aba86ed..185bcb9 100644
--- app/code/core/Mage/Core/Controller/Request/Http.php
+++ app/code/core/Mage/Core/Controller/Request/Http.php
@@ -148,7 +148,10 @@ class Mage_Core_Controller_Request_Http extends Zend_Controller_Request_Http
             $baseUrl = $this->getBaseUrl();
             $pathInfo = substr($requestUri, strlen($baseUrl));
 
-            if ((null !== $baseUrl) && (false === $pathInfo)) {
+            if ($baseUrl && $pathInfo && (0 !== stripos($pathInfo, '/'))) {
+                $pathInfo = '';
+                $this->setActionName('noRoute');
+            } elseif ((null !== $baseUrl) && (false === $pathInfo)) {
                 $pathInfo = '';
             } elseif (null === $baseUrl) {
                 $pathInfo = $requestUri;
diff --git app/code/core/Mage/Core/Model/File/Validator/Image.php app/code/core/Mage/Core/Model/File/Validator/Image.php
index 3fb8e3a..39f9cb0 100644
--- app/code/core/Mage/Core/Model/File/Validator/Image.php
+++ app/code/core/Mage/Core/Model/File/Validator/Image.php
@@ -87,10 +87,51 @@ class Mage_Core_Model_File_Validator_Image
      */
     public function validate($filePath)
     {
-        $fileInfo = getimagesize($filePath);
-        if (is_array($fileInfo) and isset($fileInfo[2])) {
-            if ($this->isImageType($fileInfo[2])) {
-                return null;
+        list($imageWidth, $imageHeight, $fileType) = getimagesize($filePath);
+        if ($fileType) {
+            if ($this->isImageType($fileType)) {
+                //replace tmp image with re-sampled copy to exclude images with malicious data
+                $image = imagecreatefromstring(file_get_contents($filePath));
+                if ($image !== false) {
+                    $img = imagecreatetruecolor($imageWidth, $imageHeight);
+                    imagealphablending($img, false);
+                    imagecopyresampled($img, $image, 0, 0, 0, 0, $imageWidth, $imageHeight, $imageWidth, $imageHeight);
+                    imagesavealpha($img, true);
+
+                    switch ($fileType) {
+                        case IMAGETYPE_GIF:
+                            $transparencyIndex = imagecolortransparent($image);
+                            if ($transparencyIndex >= 0) {
+                                imagecolortransparent($img, $transparencyIndex);
+                                for ($y = 0; $y < $imageHeight; ++$y) {
+                                    for ($x = 0; $x < $imageWidth; ++$x) {
+                                        if (((imagecolorat($img, $x, $y) >> 24) & 0x7F)) {
+                                            imagesetpixel($img, $x, $y, $transparencyIndex);
+                                        }
+                                    }
+                                }
+                            }
+                            if (!imageistruecolor($image)) {
+                                imagetruecolortopalette($img, false, imagecolorstotal($image));
+                            }
+                            imagegif($img, $filePath);
+                            break;
+                        case IMAGETYPE_JPEG:
+                            imagejpeg($img, $filePath, 100);
+                            break;
+                        case IMAGETYPE_PNG:
+                            imagepng($img, $filePath);
+                            break;
+                        default:
+                            break;
+                    }
+
+                    imagedestroy($img);
+                    imagedestroy($image);
+                    return null;
+                } else {
+                    throw Mage::exception('Mage_Core', Mage::helper('core')->__('Invalid image.'));
+                }
             }
         }
         throw Mage::exception('Mage_Core', Mage::helper('core')->__('Invalid MIME type.'));
@@ -105,5 +146,4 @@ class Mage_Core_Model_File_Validator_Image
     {
         return in_array($nImageType, $this->_allowedImageTypes);
     }
-
 }
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 2e9a1ff..52493b2 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Core>
-            <version>1.6.0.2</version>
+            <version>1.6.0.2.1.2</version>
         </Mage_Core>
     </modules>
     <global>
@@ -261,6 +261,9 @@
             </js>
         </dev>
         <system>
+            <csrf>
+                <use_form_key>1</use_form_key>
+            </csrf>
             <smtp>
                 <disable>0</disable>
                 <host>localhost</host>
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index 604b206..5e31988 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -41,6 +41,29 @@
         </advanced>
     </tabs>
     <sections>
+        <system>
+            <groups>
+                <csrf translate="label" module="core">
+                    <label>CSRF protection</label>
+                    <frontend_type>text</frontend_type>
+                    <sort_order>0</sort_order>
+                    <show_in_default>1</show_in_default>
+                    <show_in_website>0</show_in_website>
+                    <show_in_store>0</show_in_store>
+                    <fields>
+                        <use_form_key translate="label">
+                            <label>Add Secret Key To Url</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>10</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </use_form_key>
+                    </fields>
+                </csrf>
+            </groups>
+        </system>
         <!--<web_track translate="label" module="core">
             <label>Web Tracking</label>
             <frontend_type>text</frontend_type>
@@ -504,18 +527,19 @@
                     <label>Template Settings</label>
                     <frontend_type>text</frontend_type>
                     <sort_order>25</sort_order>
-                    <show_in_default>1</show_in_default>
-                    <show_in_website>1</show_in_website>
-                    <show_in_store>1</show_in_store>
+                    <show_in_default>0</show_in_default>
+                    <show_in_website>0</show_in_website>
+                    <show_in_store>0</show_in_store>
                     <fields>
                         <allow_symlink translate="label comment">
                             <label>Allow Symlinks</label>
                             <frontend_type>select</frontend_type>
                             <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <backend_model>adminhtml/system_config_backend_symlink</backend_model>
                             <sort_order>10</sort_order>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>1</show_in_store>
+                            <show_in_default>0</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
                             <comment>Warning! Enabling this feature is not recommended on production environments because it represents a potential security risk.</comment>
                         </allow_symlink>
                     </fields>
diff --git app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.2.1.1-1.6.0.2.1.2.php app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.2.1.1-1.6.0.2.1.2.php
new file mode 100644
index 0000000..0f7b551
--- /dev/null
+++ app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.2.1.1-1.6.0.2.1.2.php
@@ -0,0 +1,40 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Core
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/* @var $installer Mage_Core_Model_Resource_Setup */
+$installer = $this;
+
+$installer->startSetup();
+$connection = $installer->getConnection();
+
+$connection->delete(
+    $this->getTable('core_config_data'),
+    $connection->prepareSqlCondition('path', array(
+        'like' => 'dev/template/allow_symlink'
+    ))
+);
+
+$installer->endSetup();
diff --git app/code/core/Mage/Customer/Model/Session.php app/code/core/Mage/Customer/Model/Session.php
index 07e81b4..744a12c 100644
--- app/code/core/Mage/Customer/Model/Session.php
+++ app/code/core/Mage/Customer/Model/Session.php
@@ -212,7 +212,6 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
 
         if ($customer->authenticate($username, $password)) {
             $this->setCustomerAsLoggedIn($customer);
-            $this->renewSession();
             return true;
         }
         return false;
@@ -221,6 +220,8 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
     public function setCustomerAsLoggedIn($customer)
     {
         $this->setCustomer($customer);
+        $this->renewSession();
+        Mage::getSingleton('core/session')->renewFormKey();
         Mage::dispatchEvent('customer_login', array('customer'=>$customer));
         return $this;
     }
@@ -252,6 +253,7 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
             Mage::dispatchEvent('customer_logout', array('customer' => $this->getCustomer()) );
             $this->setId(null);
             $this->getCookie()->delete($this->getSessionName());
+            Mage::getSingleton('core/session')->renewFormKey();
         }
         return $this;
     }
diff --git app/code/core/Mage/Customer/controllers/AccountController.php app/code/core/Mage/Customer/controllers/AccountController.php
index 6aa708f..1b5889b 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -339,7 +339,6 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             $url = $this->_getUrl('*/*/index', array('_secure' => true));
         } else {
             $session->setCustomerAsLoggedIn($customer);
-            $session->renewSession();
             $url = $this->_welcomeCustomer($customer);
         }
         $this->_redirectSuccess($url);
@@ -592,7 +591,6 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     throw new Exception($this->__('Failed to confirm customer account.'));
                 }
 
-                $session->renewSession();
                 // log in and send greeting email, then die happy
                 $session->setCustomerAsLoggedIn($customer);
                 $successUrl = $this->_welcomeCustomer($customer, true);
diff --git app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
index aba25aa..c9fb959 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
@@ -40,6 +40,9 @@ class Mage_Dataflow_Model_Convert_Adapter_Zend_Cache extends Mage_Dataflow_Model
         if (!$this->_resource) {
             $this->_resource = Zend_Cache::factory($this->getVar('frontend', 'Core'), $this->getVar('backend', 'File'));
         }
+        if ($this->_resource->getBackend() instanceof Zend_Cache_Backend_Static) {
+            throw new Exception(Mage::helper('dataflow')->__('Backend name "Static" not supported.'));
+        }
         return $this->_resource;
     }
 
diff --git app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
index 2b7c454..b3375eb 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
@@ -47,6 +47,18 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
 
     protected $_position;
 
+    /**
+     * Detect serialization of data
+     *
+     * @param mixed $data
+     * @return bool
+     */
+    protected function isSerialized($data)
+    {
+        $pattern = '/^a:\d+:\{(i:\d+;|s:\d+:\".+\";|N;|O:\d+:\"\w+\":\d+:\{\w:\d+:)+|^O:\d+:\"\w+\":\d+:\{s:\d+:\"/';
+        return (is_string($data) && preg_match($pattern, $data));
+    }
+
     public function getVar($key, $default=null)
     {
         if (!isset($this->_vars[$key]) || (!is_array($this->_vars[$key]) && strlen($this->_vars[$key]) == 0)) {
@@ -102,13 +114,45 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
 
     public function setData($data)
     {
-        if ($this->getProfile()) {
-            $this->getProfile()->getContainer()->setData($data);
+        if ($this->validateDataSerialized($data)) {
+            if ($this->getProfile()) {
+                $this->getProfile()->getContainer()->setData($data);
+            }
+
+            $this->_data = $data;
         }
-        $this->_data = $data;
+
         return $this;
     }
 
+    /**
+     * Validate serialized data
+     *
+     * @param mixed $data
+     * @return bool
+     */
+    public function validateDataSerialized($data = null)
+    {
+        if (is_null($data)) {
+            $data = $this->getData();
+        }
+
+        $result = true;
+        if ($this->isSerialized($data)) {
+            try {
+                $dataArray = Mage::helper('core/unserializeArray')->unserialize($data);
+            } catch (Exception $e) {
+                $result = false;
+                $this->addException(
+                    "Invalid data, expecting serialized array.",
+                    Mage_Dataflow_Model_Convert_Exception::FATAL
+                );
+            }
+        }
+
+        return $result;
+    }
+
     public function validateDataString($data=null)
     {
         if (is_null($data)) {
@@ -140,7 +184,10 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
             if (count($data)==0) {
                 return true;
             }
-            $this->addException("Invalid data type, expecting 2D grid array.", Mage_Dataflow_Model_Convert_Exception::FATAL);
+            $this->addException(
+                "Invalid data type, expecting 2D grid array.",
+                Mage_Dataflow_Model_Convert_Exception::FATAL
+            );
         }
         return true;
     }
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
index 450a6dd..3868ce6 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
@@ -77,8 +77,8 @@ class Mage_Dataflow_Model_Convert_Parser_Csv extends Mage_Dataflow_Model_Convert
         $batchIoAdapter = $this->getBatchModel()->getIoAdapter();
 
         if (Mage::app()->getRequest()->getParam('files')) {
-            $file = Mage::app()->getConfig()->getTempVarDir().'/import/'
-                . urldecode(Mage::app()->getRequest()->getParam('files'));
+            $file = Mage::app()->getConfig()->getTempVarDir() . '/import/'
+                . str_replace('../', '', urldecode(Mage::app()->getRequest()->getParam('files')));
             $this->_copy($file);
         }
 
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
index 80abebc..d0c75f7 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
@@ -78,8 +78,8 @@ class Mage_Dataflow_Model_Convert_Parser_Xml_Excel extends Mage_Dataflow_Model_C
         $batchIoAdapter = $this->getBatchModel()->getIoAdapter();
 
         if (Mage::app()->getRequest()->getParam('files')) {
-            $file = Mage::app()->getConfig()->getTempVarDir().'/import/'
-                . urldecode(Mage::app()->getRequest()->getParam('files'));
+            $file = Mage::app()->getConfig()->getTempVarDir() . '/import/'
+                . str_replace('../', '', urldecode(Mage::app()->getRequest()->getParam('files')));
             $this->_copy($file);
         }
 
diff --git app/code/core/Mage/ImportExport/Model/Import/Uploader.php app/code/core/Mage/ImportExport/Model/Import/Uploader.php
index afc1947..fad34ea 100644
--- app/code/core/Mage/ImportExport/Model/Import/Uploader.php
+++ app/code/core/Mage/ImportExport/Model/Import/Uploader.php
@@ -61,6 +61,11 @@ class Mage_ImportExport_Model_Import_Uploader extends Mage_Core_Model_File_Uploa
         $this->setAllowedExtensions(array_keys($this->_allowedMimeTypes));
         $this->addValidateCallback('catalog_product_image',
                 Mage::helper('catalog/image'), 'validateUploadFile');
+        $this->addValidateCallback(
+            Mage_Core_Model_File_Validator_Image::NAME,
+            Mage::getModel('core/file_validator_image'),
+            'validate'
+        );
         $this->_uploadType = self::SINGLE_STYLE;
     }
 
diff --git app/code/core/Mage/Sales/Model/Quote/Item.php app/code/core/Mage/Sales/Model/Quote/Item.php
index 50d5eb8..1866b39 100644
--- app/code/core/Mage/Sales/Model/Quote/Item.php
+++ app/code/core/Mage/Sales/Model/Quote/Item.php
@@ -500,8 +500,9 @@ class Mage_Sales_Model_Quote_Item extends Mage_Sales_Model_Quote_Item_Abstract
                         /** @var Unserialize_Parser $parser */
                         $parser = Mage::helper('core/unserializeArray');
 
-                        $_itemOptionValue = $parser->unserialize($itemOptionValue);
-                        $_optionValue = $parser->unserialize($optionValue);
+                        $_itemOptionValue =
+                            is_numeric($itemOptionValue) ? $itemOptionValue : $parser->unserialize($itemOptionValue);
+                        $_optionValue = is_numeric($optionValue) ? $optionValue : $parser->unserialize($optionValue);
 
                         if (is_array($_itemOptionValue) && is_array($_optionValue)) {
                             $itemOptionValue = $_itemOptionValue;
diff --git app/code/core/Mage/Widget/Model/Widget/Instance.php app/code/core/Mage/Widget/Model/Widget/Instance.php
index c85b0c7..d5ba66d 100644
--- app/code/core/Mage/Widget/Model/Widget/Instance.php
+++ app/code/core/Mage/Widget/Model/Widget/Instance.php
@@ -340,7 +340,11 @@ class Mage_Widget_Model_Widget_Instance extends Mage_Core_Model_Abstract
     public function getWidgetParameters()
     {
         if (is_string($this->getData('widget_parameters'))) {
-            return unserialize($this->getData('widget_parameters'));
+            try {
+                return Mage::helper('core/unserializeArray')->unserialize($this->getData('widget_parameters'));
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
         }
         return $this->getData('widget_parameters');
     }
diff --git app/code/core/Mage/XmlConnect/Helper/Image.php app/code/core/Mage/XmlConnect/Helper/Image.php
index 7d94289..28a989d 100644
--- app/code/core/Mage/XmlConnect/Helper/Image.php
+++ app/code/core/Mage/XmlConnect/Helper/Image.php
@@ -92,6 +92,11 @@ class Mage_XmlConnect_Helper_Image extends Mage_Core_Helper_Abstract
             $uploader = Mage::getModel('core/file_uploader', $field);
             $uploader->setAllowedExtensions(array('jpg', 'jpeg', 'gif', 'png'));
             $uploader->setAllowRenameFiles(true);
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                Mage::getModel('core/file_validator_image'),
+                'validate'
+            );
             $uploader->save($uploadDir);
             $uploadedFilename = $uploader->getUploadedFileName();
             $uploadedFilename = $this->_getResizedFilename($field, $uploadedFilename, true);
diff --git app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
index 8b81bca..dc1d4a7 100644
--- app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
+++ app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
@@ -535,7 +535,7 @@ class Mage_XmlConnect_Adminhtml_MobileController extends Mage_Adminhtml_Controll
                 $result = $themesHelper->deleteTheme($themeId);
                 if ($result) {
                     $response = array(
-                        'message'   => $this->__('Theme has been delete.'),
+                        'message'   => $this->__('Theme has been deleted.'),
                         'themes'    => $themesHelper->getAllThemesArray(true),
                         'themeSelector' => $themesHelper->getThemesSelector(),
                         'selectedTheme' => $themesHelper->getDefaultThemeName()
diff --git app/design/adminhtml/default/default/layout/main.xml app/design/adminhtml/default/default/layout/main.xml
index 2a17e95..676eff0 100644
--- app/design/adminhtml/default/default/layout/main.xml
+++ app/design/adminhtml/default/default/layout/main.xml
@@ -118,6 +118,8 @@ Default layout, loads most of the pages
                 <block type="adminhtml/cache_notifications" name="cache_notifications" template="system/cache/notifications.phtml"></block>
                 <block type="adminhtml/notification_survey" name="notification_survey" template="notification/survey.phtml"/>
                 <block type="adminhtml/notification_security" name="notification_security" as="notification_security" template="notification/security.phtml"></block>
+                <block type="adminhtml/checkout_formkey" name="checkout_formkey" as="checkout_formkey" template="notification/formkey.phtml"/>
+                <block type="adminhtml/notification_symlink" name="notification_symlink" template="notification/symlink.phtml"/>
             </block>
             <block type="adminhtml/widget_breadcrumbs" name="breadcrumbs" as="breadcrumbs"></block>
 
diff --git app/design/adminhtml/default/default/template/notification/formkey.phtml app/design/adminhtml/default/default/template/notification/formkey.phtml
new file mode 100644
index 0000000..31bec75
--- /dev/null
+++ app/design/adminhtml/default/default/template/notification/formkey.phtml
@@ -0,0 +1,38 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Academic Free License (AFL 3.0)
+ * that is bundled with this package in the file LICENSE_AFL.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/afl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    design
+ * @package     default_default
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/afl-3.0.php  Academic Free License (AFL 3.0)
+ */
+/**
+ * @see Mage_Adminhtml_Block_Checkout_Formkey
+ */
+?>
+<?php if ($this->canShow()): ?>
+    <div class="notification-global notification-global-warning">
+        <strong style="color:red">Important: </strong>
+        <span>Formkey validation on checkout disabled. This may expose security risks.
+        We strongly recommend to Enable Form Key Validation On Checkout in
+        <a href="<?php echo $this->getSecurityAdminUrl(); ?>">Admin / Security Section</a>,
+        for protect your own checkout process. </span>
+    </div>
+<?php endif; ?>
diff --git app/design/adminhtml/default/default/template/notification/symlink.phtml app/design/adminhtml/default/default/template/notification/symlink.phtml
new file mode 100644
index 0000000..acffa8b
--- /dev/null
+++ app/design/adminhtml/default/default/template/notification/symlink.phtml
@@ -0,0 +1,34 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Academic Free License (AFL 3.0)
+ * that is bundled with this package in the file LICENSE_AFL.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/afl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    design
+ * @package     default_default
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/afl-3.0.php  Academic Free License (AFL 3.0)
+ */
+/**
+ * @see Mage_Adminhtml_Block_Notification_Symlink
+ */
+?>
+<?php if ($this->isSymlinkEnabled()): ?>
+    <div class="notification-global notification-global-warning">
+        <?php echo $this->helper('adminhtml')->__('Symlinks are enabled. This may expose security risks. We strongly recommend to disable them.')?>
+    </div>
+<?php endif; ?>
diff --git app/design/adminhtml/default/default/template/page/head.phtml app/design/adminhtml/default/default/template/page/head.phtml
index 8f8b5ba..312a707 100644
--- app/design/adminhtml/default/default/template/page/head.phtml
+++ app/design/adminhtml/default/default/template/page/head.phtml
@@ -10,7 +10,7 @@
     var BLANK_URL = '<?php echo $this->getJsUrl() ?>blank.html';
     var BLANK_IMG = '<?php echo $this->getJsUrl() ?>spacer.gif';
     var BASE_URL = '<?php echo $this->getUrl('*') ?>';
-    var SKIN_URL = '<?php echo $this->getSkinUrl() ?>';
+    var SKIN_URL = '<?php echo $this->jsQuoteEscape($this->getSkinUrl()) ?>';
     var FORM_KEY = '<?php echo $this->getFormKey() ?>';
 </script>
 
diff --git app/design/frontend/base/default/template/checkout/cart/shipping.phtml app/design/frontend/base/default/template/checkout/cart/shipping.phtml
index 19a95e5..2b24017 100644
--- app/design/frontend/base/default/template/checkout/cart/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/cart/shipping.phtml
@@ -113,6 +113,7 @@
             <div class="buttons-set">
                 <button type="submit" title="<?php echo $this->__('Update Total') ?>" class="button" name="do" value="<?php echo $this->__('Update Total') ?>"><span><span><?php echo $this->__('Update Total') ?></span></span></button>
             </div>
+            <?php echo $this->getBlockHtml('formkey') ?>
         </form>
         <?php endif; ?>
         <script type="text/javascript">
diff --git app/design/frontend/base/default/template/checkout/multishipping/addresses.phtml app/design/frontend/base/default/template/checkout/multishipping/addresses.phtml
index f063a43..a1bdc46 100644
--- app/design/frontend/base/default/template/checkout/multishipping/addresses.phtml
+++ app/design/frontend/base/default/template/checkout/multishipping/addresses.phtml
@@ -78,4 +78,5 @@
             <button type="submit" title="<?php echo $this->__('Continue to Shipping Information') ?>" class="button<?php if ($this->isContinueDisabled()):?> disabled<?php endif; ?>" onclick="$('can_continue_flag').value=1"<?php if ($this->isContinueDisabled()):?> disabled="disabled"<?php endif; ?>><span><span><?php echo $this->__('Continue to Shipping Information') ?></span></span></button>
         </div>
     </div>
+    <?php echo $this->getBlockHtml("formkey") ?>
 </form>
diff --git app/design/frontend/base/default/template/checkout/multishipping/billing.phtml app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
index 599035a..58da8fd 100644
--- app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
+++ app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
@@ -91,6 +91,7 @@
             <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Shipping Information') ?></a></p>
             <button type="submit" title="<?php echo $this->__('Continue to Review Your Order') ?>" class="button"><span><span><?php echo $this->__('Continue to Review Your Order') ?></span></span></button>
         </div>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </form>
     <script type="text/javascript">
     //<![CDATA[
diff --git app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
index 8d826b3..18e6681 100644
--- app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
@@ -125,5 +125,6 @@
             <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Select Addresses') ?></a></p>
             <button type="submit" title="<?php echo $this->__('Continue to Billing Information') ?>" class="button"><span><span><?php echo $this->__('Continue to Billing Information') ?></span></span></button>
         </div>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </form>
 </div>
diff --git app/design/frontend/base/default/template/checkout/onepage/billing.phtml app/design/frontend/base/default/template/checkout/onepage/billing.phtml
index 72159fa..8324493 100644
--- app/design/frontend/base/default/template/checkout/onepage/billing.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/billing.phtml
@@ -188,6 +188,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
 <script type="text/javascript">
diff --git app/design/frontend/base/default/template/checkout/onepage/payment.phtml app/design/frontend/base/default/template/checkout/onepage/payment.phtml
index 8cae3a7..d03f73a 100644
--- app/design/frontend/base/default/template/checkout/onepage/payment.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/payment.phtml
@@ -36,6 +36,7 @@
     <fieldset>
         <?php echo $this->getChildHtml('methods') ?>
     </fieldset>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <div class="tool-tip" id="payment-tool-tip" style="display:none;">
     <div class="btn-close"><a href="#" id="payment-tool-tip-close" title="<?php echo $this->__('Close') ?>"><?php echo $this->__('Close') ?></a></div>
diff --git app/design/frontend/base/default/template/checkout/onepage/shipping.phtml app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
index e66b6f1..60a14ef 100644
--- app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
@@ -139,6 +139,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
index 0418308..64e2286 100644
--- app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
@@ -43,4 +43,5 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
diff --git app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
index 56be402..4f9d35e 100644
--- app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
+++ app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
@@ -188,6 +188,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
 <script type="text/javascript">
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index fd84957..aa1aa01 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -1131,3 +1131,5 @@
 "to","to"
 "website(%s) scope","website(%s) scope"
 "{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>.","{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>."
+"You did not sign in correctly or your account is temporarily disabled.","You did not sign in correctly or your account is temporarily disabled."
+"Symlinks are enabled. This may expose security risks. We strongly recommend to disable them.","Symlinks are enabled. This may expose security risks. We strongly recommend to disable them."
diff --git app/locale/en_US/Mage_Core.csv app/locale/en_US/Mage_Core.csv
index 663ea1a..258a5f5 100644
--- app/locale/en_US/Mage_Core.csv
+++ app/locale/en_US/Mage_Core.csv
@@ -375,3 +375,4 @@
 "Your order cannot be completed at this time as there is no shipping methods available for it. Please make necessary changes in your shipping address.","Your order cannot be completed at this time as there is no shipping methods available for it. Please make necessary changes in your shipping address."
 "Your session has been expired, you will be relogged in now.","Your session has been expired, you will be relogged in now."
 "database ""%s""","database ""%s"""
+"Invalid image.","Invalid image."
diff --git app/locale/en_US/Mage_Dataflow.csv app/locale/en_US/Mage_Dataflow.csv
index 7169fae..50bac5f 100644
--- app/locale/en_US/Mage_Dataflow.csv
+++ app/locale/en_US/Mage_Dataflow.csv
@@ -30,3 +30,4 @@
 "hours","hours"
 "minute","minute"
 "minutes","minutes"
+"Backend name "Static" not supported.","Backend name "Static" not supported."
diff --git app/locale/en_US/Mage_XmlConnect.csv app/locale/en_US/Mage_XmlConnect.csv
index 9af43b0..1b74002 100644
--- app/locale/en_US/Mage_XmlConnect.csv
+++ app/locale/en_US/Mage_XmlConnect.csv
@@ -551,7 +551,7 @@
 "The store credit payment has been removed from shopping cart.","The store credit payment has been removed from shopping cart."
 "Theme configurations are successfully reset.","Theme configurations are successfully reset."
 "Theme has been created.","Theme has been created."
-"Theme has been delete.","Theme has been delete."
+"Theme has been deleted.","Theme has been deleted."
 "Theme label can\'t be empty","Theme label can\'t be empty"
 "Theme label:","Theme label:"
 "Theme name is not set.","Theme name is not set."
diff --git downloader/Maged/Connect.php downloader/Maged/Connect.php
index f1df349..01abb76 100644
--- downloader/Maged/Connect.php
+++ downloader/Maged/Connect.php
@@ -318,7 +318,9 @@ class Maged_Connect
         }
 
         if (!$run->get('no-header')) {
-?>
+            $validateKey = md5(time());
+            $sessionModel = new Maged_Model_Session();
+            $sessionModel->set('validate_cache_key', $validateKey); ?>
 <html><head><style type="text/css">
 body { margin:0px;
     padding:3px;
@@ -364,6 +366,7 @@ function clear_cache(callbacks)
     var intervalID = setInterval(function() {show_message('.', false); }, 500);
     var clean = 0;
     var maintenance = 0;
+    var validate_cache_key = '<?php echo $validateKey; ?>';
     if (window.location.href.indexOf('clean_sessions') >= 0) {
         clean = 1;
     }
@@ -373,7 +376,7 @@ function clear_cache(callbacks)
 
     new top.Ajax.Request(url, {
         method: 'post',
-        parameters: {clean_sessions:clean, maintenance:maintenance},
+        parameters: {clean_sessions:clean, maintenance:maintenance, validate_cache_key:validate_cache_key},
         onCreate: function() {
             show_message('Cleaning cache');
             show_message('');
diff --git downloader/Maged/Controller.php downloader/Maged/Controller.php
index c03ab49b..30f9db3 100755
--- downloader/Maged/Controller.php
+++ downloader/Maged/Controller.php
@@ -405,7 +405,7 @@ final class Maged_Controller
      */
     public function cleanCacheAction()
     {
-        $result = $this->cleanCache();
+        $result = $this->cleanCache(true);
         echo json_encode($result);
     }
 
@@ -904,25 +904,36 @@ final class Maged_Controller
         }
     }
 
-    protected function cleanCache()
+    /**
+     * Clean cache
+     *
+     * @param bool $validate
+     * @return array
+     */
+    protected function cleanCache($validate = false)
     {
         $result = true;
         $message = '';
         try {
             if ($this->isInstalled()) {
-                if (!empty($_REQUEST['clean_sessions'])) {
-                    Mage::app()->cleanAllSessions();
-                    $message .= 'Session cleaned successfully. ';
+                if ($validate) {
+                    $result = $this->session()->validateCleanCacheKey();
+                }
+                if ($result) {
+                    if (!empty($_REQUEST['clean_sessions'])) {
+                        Mage::app()->cleanAllSessions();
+                        $message .= 'Session cleaned successfully. ';
+                    }
+                    Mage::app()->cleanCache();
+
+                    // reinit config and apply all updates
+                    Mage::app()->getConfig()->reinit();
+                    Mage_Core_Model_Resource_Setup::applyAllUpdates();
+                    Mage_Core_Model_Resource_Setup::applyAllDataUpdates();
+                    $message .= 'Cache cleaned successfully';
+                } else {
+                    $message .= 'Validation failed';
                 }
-                Mage::app()->cleanCache();
-
-                // reinit config and apply all updates
-                Mage::app()->getConfig()->reinit();
-                Mage_Core_Model_Resource_Setup::applyAllUpdates();
-                Mage_Core_Model_Resource_Setup::applyAllDataUpdates();
-                $message .= 'Cache cleaned successfully';
-            } else {
-                $result = true;
             }
         } catch (Exception $e) {
             $result = false;
diff --git downloader/Maged/Model/Session.php downloader/Maged/Model/Session.php
index 26ab58d..cee8208 100644
--- downloader/Maged/Model/Session.php
+++ downloader/Maged/Model/Session.php
@@ -82,6 +82,20 @@ class Maged_Model_Session extends Maged_Model
     }
 
     /**
+     * Unset value by key
+     *
+     * @param string $key
+     * @return $this
+     */
+    public function delete($key)
+    {
+        if (isset($_SESSION[$key])) {
+            unset($_SESSION[$key]);
+        }
+        return $this;
+    }
+
+    /**
      * Authentication to downloader
      */
     public function authenticate()
@@ -234,4 +248,24 @@ class Maged_Model_Session extends Maged_Model
         }
         return $this->get('_form_key');
     }
+
+    /**
+     * Validate key for cache cleaning
+     *
+     * @return bool
+     */
+    public function validateCleanCacheKey()
+    {
+        $result = false;
+        $validateKey = $this->get('validate_cache_key');
+        if ($validateKey
+            && !empty($_REQUEST['validate_cache_key'])
+            && $validateKey == $_REQUEST['validate_cache_key']
+        ) {
+            $result = true;
+        }
+        $this->delete('validate_cache_key');
+
+        return $result;
+    }
 }
diff --git js/varien/payment.js js/varien/payment.js
index 8fbb684..9a5b824 100644
--- js/varien/payment.js
+++ js/varien/payment.js
@@ -31,7 +31,7 @@ paymentForm.prototype = {
 
         var method = null;
         for (var i=0; i<elements.length; i++) {
-            if (elements[i].name=='payment[method]') {
+            if (elements[i].name=='payment[method]' || elements[i].name=='form_key') {
                 if (elements[i].checked) {
                     method = elements[i].value;
                 }
diff --git skin/frontend/base/default/js/opcheckout.js skin/frontend/base/default/js/opcheckout.js
index ae83e7e..466e15f 100644
--- skin/frontend/base/default/js/opcheckout.js
+++ skin/frontend/base/default/js/opcheckout.js
@@ -634,7 +634,7 @@ Payment.prototype = {
         }
         var method = null;
         for (var i=0; i<elements.length; i++) {
-            if (elements[i].name=='payment[method]') {
+            if (elements[i].name=='payment[method]' || elements[i].name == 'form_key') {
                 if (elements[i].checked) {
                     method = elements[i].value;
                 }

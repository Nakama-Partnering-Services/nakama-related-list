@SuppressWarnings('PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class ColumnConfig {
	@AuraEnabled
	public CellAttributes cellAttributes;
	@AuraEnabled
	public Boolean editable;
	@AuraEnabled
	public Boolean displayReadOnlyIcon;
	@AuraEnabled
	public String fieldName;
	@AuraEnabled
	public Boolean hideDefaultActions;
	@AuraEnabled
	public String label;
	@AuraEnabled
	public Boolean searchable;
	@AuraEnabled
	public Boolean sortable;
	@AuraEnabled
	public String type;
	@AuraEnabled
	public TypeAttributes typeAttributes;

	// Documentation states that Date and Datetime fields are no inline editable but it is not true
	// Types of number are not editable since they are passed as text and causing an exception
	private final static Set<DisplayType> NON_EDITABLE_TYPES = new Set<DisplayType>{
		DisplayType.ADDRESS,
		DisplayType.DOUBLE,
		DisplayType.INTEGER,
		DisplayType.LONG
	};

	private Map<DisplayType, String> formattingTypesByFieldType = new Map<DisplayType, String>{
		DisplayType.BOOLEAN => 'boolean',
		DisplayType.COMBOBOX => 'text',
		DisplayType.CURRENCY => 'currency',
		DisplayType.DATE => 'date',
		DisplayType.DATETIME => 'date',
		DisplayType.DOUBLE => 'number',
		DisplayType.EMAIL => 'url',
		DisplayType.ID => 'text',
		DisplayType.INTEGER => 'number',
		DisplayType.LONG => 'number',
		DisplayType.MULTIPICKLIST => 'text',
		DisplayType.PERCENT => 'percent',
		DisplayType.PHONE => 'phone',
		DisplayType.PICKLIST => 'text',
		DisplayType.STRING => 'text',
		DisplayType.TEXTAREA => 'text',
		DisplayType.TIME => 'date',
		DisplayType.URL => 'url',
		DisplayType.REFERENCE => 'reference'
	};

	// CONSTRUCTOR

	@SuppressWarnings('PMD.ExcessiveParameterList')
	public ColumnConfig(
		FieldSetMember field,
		Boolean hideDefaultActions,
		Boolean sortable,
		Boolean editable,
		Boolean searchable
	) {
		this.hideDefaultActions = hideDefaultActions == null ? false : hideDefaultActions;
		this.sortable = sortable == null ? false : sortable;
		this.editable = editable == null ? false : editable;
		this.searchable = searchable == null ? false : searchable;
		initColumnConfig(field);
	}

	// PRIVATE

	private void initColumnConfig(FieldSetMember field) {
		String fieldPath = field.getFieldPath();
		label = fieldPath.contains('.') ? getRelationalLabel(fieldPath) : field.getLabel();

		// TODO: Use getNameField from fflib_SObjectDescribe to avoid issues with, for example, CaseNumber
		if (field.getType() == DisplayType.REFERENCE) {
			if (field.getFieldPath().endsWith('__c')) {
				fieldPath = field.getFieldPath().replace('__c', '__r.Name');
			} else if (field.getFieldPath().endsWith('Id')) {
				// Trick to no to replace other possible appearances of 'Id' in the field name
				fieldPath = field.getFieldPath() + '__';
				fieldPath = fieldPath.replace('Id__', '.Name');
			}
		}

		// TODO: Use getNameField from fflib_SObjectDescribe to avoid issues with, for example, CaseNumber
		if (fieldPath == 'Name' || fieldPath.endsWith('.Name')) {
			fieldName = fieldPath.replace('Name', 'LinkName');
			type = 'url';
			displayReadOnlyIcon = editable;
			editable = false;
		} else {
			fieldName = fieldPath;
			final DisplayType fieldType = field.getType();
			type = formattingTypesByFieldType.get(fieldType);
			displayReadOnlyIcon = editable;
			// Note: By making a column editable, the show-row-number-column attribute is always true and the number column is displayed
			editable = editable && isUpdateable(field) && !NON_EDITABLE_TYPES.contains(fieldType);
			displayReadOnlyIcon = displayReadOnlyIcon && !editable;
		}

		if (type == 'url') {
			cellAttributes = new CellAttributes();
			typeAttributes = new TypeAttributes(fieldPath);
		}

		if (type == 'boolean') {
			searchable = false;
		}
	}

	private String getRelationalLabel(String fieldPath) {
		// TODO: currently using field sets, only one parent level is allowed,
		// but this is not really accurate, it should be a recursive method (since there may be multiple levels)
		// TODO: retrieving proper labels for each relationship until the last field, otherwise there will be an
		// issue if api name does not correspond to label

		String result = fieldPath.replace('__r', '').replace('__c', '').replace('.', ' ').replace('_', ' ');
		result = String.join(result.splitByCharacterTypeCamelCase(), ' ');
		return result;
	}

	// Note: this is wrongly reported because, for fields, DEFAULT is better than FULL_DESCRIBE
	@SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
	private Boolean isUpdateable(FieldSetMember field) {
		return field.getSObjectField().getDescribe().isUpdateable();
	}

	// INNER

	private with sharing class TypeAttributes {
		@AuraEnabled
		public Label label;
		@AuraEnabled
		public String target;

		public TypeAttributes(String fieldName) {
			label = new Label(fieldName);
			target = '_top';
		}
	}

	private with sharing class Label {
		@AuraEnabled
		public String fieldName;

		public Label(String fieldName) {
			this.fieldName = fieldName;
		}
	}

	private with sharing class CellAttributes {
		@AuraEnabled
		public String alignment;

		public CellAttributes() {
			alignment = 'left';
		}
	}
}

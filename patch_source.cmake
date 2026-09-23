# Source compatibility edits required by SkyrimPlatform.
# These are the same access changes the official SkyMP overlay carries for its
# older CommonLib pin, adapted to CommonLibSSE-NG v7.5.4.

function(ar_replace filepath needle replacement description)
  if(NOT EXISTS "${filepath}")
    message(FATAL_ERROR "Aventura RP port: file not found: ${filepath}")
  endif()
  file(READ "${filepath}" _ar_content)
  string(FIND "${_ar_content}" "${needle}" _ar_pos)
  if(_ar_pos EQUAL -1)
    message(FATAL_ERROR "Aventura RP port: source edit not applicable (${description}) in ${filepath}")
  endif()
  string(REPLACE "${needle}" "${replacement}" _ar_content "${_ar_content}")
  file(WRITE "${filepath}" "${_ar_content}")
  message(STATUS "Aventura RP port: applied ${description}")
endfunction()

ar_replace(
  "${SOURCE_PATH}/include/RE/T/TESObjectREFR.h"
  [=[		void              MoveTo_Impl(const ObjectRefHandle& a_targetHandle, TESObjectCELL* a_targetCell, TESWorldSpace* a_selfWorldSpace, const NiPoint3& a_position, const NiPoint3& a_rotation);]=]
  [=[	public:
		void              MoveTo_Impl(const ObjectRefHandle& a_targetHandle, TESObjectCELL* a_targetCell, TESWorldSpace* a_selfWorldSpace, const NiPoint3& a_position, const NiPoint3& a_rotation);
	private:]=]
  "TESObjectREFR::MoveTo_Impl visibility"
)

ar_replace(
  "${SOURCE_PATH}/include/RE/V/Variable.h"
  [=[			// members
			TypeInfo varType;  // 00
			Value    value;    // 08]=]
  [=[		public:
			// members
			TypeInfo varType;  // 00
			Value    value;    // 08]=]
  "BSScript::Variable member visibility"
)

ar_replace(
  "${SOURCE_PATH}/include/RE/S/StackFrame.h"
  [=[			//Variable args[4];	40 - minimum space for 4 args is allocated]=]
  [=[			Variable                        args[0];             // 40 - trailing VM arguments]=]
  "BSScript::StackFrame trailing args"
)

ar_replace(
  "${SOURCE_PATH}/include/RE/E/ExtraDataList.h"
  [=[	private:
		[[nodiscard]] BSExtraData*     GetByTypeImpl(ExtraDataType a_type) const;]=]
  [=[	public:
		[[nodiscard]] BSExtraData*     GetByTypeImpl(ExtraDataType a_type) const;]=]
  "ExtraDataList internal visibility"
)

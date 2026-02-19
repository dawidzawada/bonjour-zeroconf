package com.margelo.nitro.dawidzawada.bonjourzeroconf

import android.util.Log
import kotlin.reflect.KClass

internal class Loggy(clazz: KClass<*>) {
  private val tag = clazz.simpleName ?: "Unknown"

  private fun format(message: String, id: String?): String =
    if (id != null) "($id) $message" else message

  fun d(message: String, id: String? = null) = Log.d(tag, format(message, id))
  fun i(message: String, id: String? = null) = Log.i(tag, format(message, id))
  fun w(message: String, id: String? = null) = Log.w(tag, format(message, id))
  fun e(message: String, id: String? = null, throwable: Throwable? = null) = Log.e(tag, format(message, id), throwable)
}
